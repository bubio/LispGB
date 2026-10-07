(in-package #:lispgb.tests)

(defun synthetic-rom (&key (type 0) (rom-code 0) (ram-code 0) (cgb 0))
  (let ((rom (make-array (ash 32768 (min rom-code 8))
                         :element-type '(unsigned-byte 8) :initial-element 0)))
    (setf (aref rom #x143) cgb (aref rom #x147) type
          (aref rom #x148) rom-code (aref rom #x149) ram-code)
    (setf (aref rom #x14d)
          (logand #xff (- (loop for i from #x134 to #x14c sum (1+ (aref rom i))))))
    rom))

(defun signals-condition-p (type thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (if (typep condition type) t (error condition)))))

(deftest cartridge-types ()
  (loop for (code kind ram battery rtc) in
        '((#x00 :rom-only nil nil nil) (#x01 :mbc1 nil nil nil)
          (#x02 :mbc1 t nil nil) (#x03 :mbc1 t t nil)
          (#x05 :mbc2 t nil nil) (#x06 :mbc2 t t nil)
          (#x0f :mbc3 nil t t) (#x10 :mbc3 t t t)
          (#x11 :mbc3 nil nil nil) (#x12 :mbc3 t nil nil) (#x13 :mbc3 t t nil)
          (#x19 :mbc5 nil nil nil) (#x1a :mbc5 t nil nil) (#x1b :mbc5 t t nil)
          (#x1c :mbc5 nil nil nil) (#x1d :mbc5 t nil nil) (#x1e :mbc5 t t nil))
        for header = (lispgb.core::parse-cartridge-header (synthetic-rom :type code :ram-code 2))
        do (is (eq kind (lispgb.core::cartridge-header-mbc-kind header)))
           (is (eq battery (lispgb.core::cartridge-header-battery-p header)))
           (is (eq rtc (lispgb.core::cartridge-header-rtc-p header)))
           (is (= (if (eq kind :mbc2) 512 (if ram 8192 0))
                  (lispgb.core::cartridge-header-ram-size header)))))

(deftest cartridge-invalid ()
  (is (signals-condition-p 'lispgb.core::invalid-rom
       (lambda () (lispgb.core::parse-cartridge-header
                    (make-array 32 :element-type '(unsigned-byte 8))))))
  (is (signals-condition-p 'lispgb.core::unsupported-cartridge
       (lambda () (lispgb.core::parse-cartridge-header (synthetic-rom :type #xff)))))
  (is (signals-condition-p 'lispgb.core::invalid-rom
       (lambda () (lispgb.core::parse-cartridge-header (synthetic-rom :rom-code 9)))))
  (is (signals-condition-p 'lispgb.core::invalid-rom
       (lambda () (lispgb.core::parse-cartridge-header (synthetic-rom :ram-code 1)))))
  (let ((rom (synthetic-rom)))
    (setf (aref rom #x148) 1)
    (is (signals-condition-p 'lispgb.core::invalid-rom
         (lambda () (lispgb.core::parse-cartridge-header rom))))))

(deftest cartridge-checksum ()
  (let ((rom (synthetic-rom :cgb #x80)) (warned nil))
    (setf (aref rom #x134) (char-code #\L)
          (aref rom #x14e) #x12 (aref rom #x14f) #x34)
    (handler-bind ((warning (lambda (condition)
                              (setf warned (typep condition 'lispgb.core::header-checksum-mismatch))
                              (muffle-warning condition))))
      (let ((header (lispgb.core::parse-cartridge-header rom)))
        (is (string= "L" (lispgb.core::cartridge-header-title header)))
        (is (= #x80 (lispgb.core::cartridge-header-cgb-flag header)))
        (is (= #x1234 (lispgb.core::cartridge-header-global-checksum header)))))
    (is warned)))
