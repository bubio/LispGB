(in-package #:lispgb.tests)

(defun run-rom (path &key (max-frames 3600) until)
  "ROM を読み込み、上限フレーム数または終了条件まで実行する。"
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let* ((rom (make-array (file-length stream) :element-type '(unsigned-byte 8)))
           (machine (progn (read-sequence rom stream) (lispgb.core:make-machine rom))))
      (loop repeat max-frames
            do (lispgb.core:run-frame machine)
            when (and until (funcall until machine)) return nil)
      machine)))

(defun serial-text (machine)
  (let ((log (lispgb.core:machine-serial-log machine)))
    (if (stringp log) log (map 'string #'code-char log))))

(defun blargg-serial-result (path &key (max-frames 3600))
  (let* ((machine (run-rom path :max-frames max-frames
                           :until (lambda (m) (let ((text (serial-text m)))
                                                (or (search "Passed" text) (search "Failed" text))))))
         (text (serial-text machine)))
    (values (cond ((search "Failed" text) :fail) ((search "Passed" text) :pass) (t :timeout)) machine)))

(defun blargg-memory-status (machine)
  (when (equal '(#xde #xb0 #x61)
               (loop for address from #xa001 to #xa003 collect (lispgb.core:machine-read-byte machine address)))
    (let ((status (lispgb.core:machine-read-byte machine #xa000)))
      (when (< status #x80) (if (zerop status) :pass :fail)))))

(defun blargg-memory-result (path &key (max-frames 3600))
  (let ((machine (run-rom path :max-frames max-frames :until #'blargg-memory-status)))
    (values (or (blargg-memory-status machine) :timeout) machine)))

(defun mooneye-result (path &key (max-frames 3600))
  (let ((machine (run-rom path :max-frames max-frames :until #'lispgb.core:machine-ld-b-b-hit-p)))
    (values (if (lispgb.core:machine-ld-b-b-hit-p machine)
                (if (equal '(3 5 8 13 21 34)
                           (loop with registers = (lispgb.core:machine-cpu-registers machine)
                                 for key in '(:b :c :d :e :h :l) collect (getf registers key))) :pass :fail)
                :timeout) machine)))

(defun framebuffer-fnv1a64 (machine)
  "ARGB の各画素を u32 リトルエンディアンとして FNV-1a に入力する。"
  (let ((hash #xcbf29ce484222325))
    (loop for pixel across (lispgb.core:machine-framebuffer machine)
          do (dotimes (i 4)
               (setf hash (ldb (byte 64 0) (* #x100000001b3 (logxor hash (ldb (byte 8 (* 8 i)) pixel)))))))
    hash))

(defun dump-framebuffer-ppm (machine path)
  (with-open-file (stream path :direction :output :if-exists :supersede :element-type '(unsigned-byte 8))
    (map nil (lambda (char) (write-byte (char-code char) stream)) (format nil "P6~%160 144~%255~%"))
    (loop for pixel across (lispgb.core:machine-framebuffer machine)
          do (dolist (shift '(16 8 0)) (write-byte (ldb (byte 8 shift) pixel) stream))))
  path)
