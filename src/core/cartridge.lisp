(in-package #:lispgb.core)
(declaim #.(core-optimize-spec))

(define-condition invalid-rom (error)
  ((reason :initarg :reason :reader invalid-rom-reason))
  (:report (lambda (condition stream)
             (format stream "ROM が不正です: ~A" (invalid-rom-reason condition)))))
(define-condition unsupported-cartridge (invalid-rom)
  ((code :initarg :code :reader unsupported-cartridge-code))
  (:report (lambda (condition stream)
             (format stream "未対応のカートリッジ種別: #x~2,'0X"
                     (unsupported-cartridge-code condition)))))
(define-condition header-checksum-mismatch (warning)
  ((expected :initarg :expected) (actual :initarg :actual))
  (:report (lambda (condition stream)
             (format stream "ROM ヘッダのチェックサムが一致しません（~2,'0X / ~2,'0X）。"
                     (slot-value condition 'expected) (slot-value condition 'actual)))))

(defstruct cartridge-header
  (title "" :type string) (cgb-flag 0 :type u8) (cartridge-type 0 :type u8)
  (rom-size 0 :type fixnum) (ram-size 0 :type fixnum)
  (header-checksum 0 :type u8) (global-checksum 0 :type u16)
  (mbc-kind :rom-only :type symbol) (battery-p nil :type boolean) (rtc-p nil :type boolean))

(defparameter *cartridge-types*
  '((#x00 :rom-only nil nil nil)
    (#x01 :mbc1 nil nil nil) (#x02 :mbc1 t nil nil) (#x03 :mbc1 t t nil)
    (#x05 :mbc2 nil nil nil) (#x06 :mbc2 nil t nil)
    (#x0f :mbc3 nil t t) (#x10 :mbc3 t t t) (#x11 :mbc3 nil nil nil)
    (#x12 :mbc3 t nil nil) (#x13 :mbc3 t t nil)
    (#x19 :mbc5 nil nil nil) (#x1a :mbc5 t nil nil) (#x1b :mbc5 t t nil)
    (#x1c :mbc5 nil nil nil) (#x1d :mbc5 t nil nil) (#x1e :mbc5 t t nil)))

(defun parse-cartridge-header (rom)
  "ROM を検証し、ヘッダを返す。警告は呼び出し側から MUFFLE-WARNING で処理できる。"
  ;; 公開境界では高速ビルドでも入力の検査を省略しない。
  (declare (optimize (safety 3)))
  (unless (and (typep rom 'octets) (>= (length rom) #x150))
    (error 'invalid-rom :reason "ヘッダに必要な 336 バイトがありません。"))
  (let* ((code (aref rom #x147)) (entry (assoc code *cartridge-types*))
         (rom-code (aref rom #x148)) (ram-code (aref rom #x149))
         (ram-entry (assoc ram-code '((0 . 0) (2 . 8192) (3 . 32768) (4 . 131072) (5 . 65536)))))
    (unless entry (error 'unsupported-cartridge :code code :reason :unsupported-type))
    (unless (<= rom-code 8) (error 'invalid-rom :reason "ROM サイズコードが未対応です。"))
    (unless ram-entry (error 'invalid-rom :reason "RAM サイズコードが未対応です。"))
    (let ((rom-size (ash 32768 rom-code))
          (checksum (wrap8 (- (loop for i from #x134 to #x14c sum (1+ (aref rom i)))))))
      (when (< (length rom) rom-size)
        (error 'invalid-rom :reason "申告された ROM サイズに対してデータが不足しています。"))
      (unless (= checksum (aref rom #x14d))
        (warn 'header-checksum-mismatch :expected checksum :actual (aref rom #x14d)))
      (destructuring-bind (code kind ram-p battery-p rtc-p) entry
        (make-cartridge-header
         :title (coerce (loop for i from #x134 below (if (member (aref rom #x143) '(#x80 #xc0)) #x143 #x144)
                              for byte = (aref rom i) until (zerop byte) collect (code-char byte)) 'string)
         :cgb-flag (aref rom #x143) :cartridge-type code
         :rom-size rom-size :ram-size (if (eq kind :mbc2) 512 (if ram-p (cdr ram-entry) 0))
         :header-checksum (aref rom #x14d)
         :global-checksum (logior (ash (aref rom #x14e) 8) (aref rom #x14f))
         :mbc-kind kind :battery-p battery-p :rtc-p rtc-p)))))
