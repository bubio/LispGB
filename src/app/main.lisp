(in-package #:lispgb)

(defun read-rom-file (path)
  (with-open-file (stream path :direction :input :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length stream) :element-type '(unsigned-byte 8))))
      (unless (= (length bytes) (read-sequence bytes stream)) (error "ROM を最後まで読めません: ~A" path))
      bytes)))
(defun sync-rtc (machine)
  (lispgb.core::mbc-sync-wall-clock (lispgb.core::bus-cart (lispgb.core::machine-bus machine))
                                  (- (get-universal-time) 2208988800)))
(defun play-machine (machine)
  (load-sdl2)
  (unwind-protect
      (progn
        (check-sdl (sdl-init #x21))
        (let ((video (open-video)))
          (unwind-protect
              (let ((audio (open-audio)) (input (make-input)))
                (unwind-protect
                    (loop
                      (when (member :quit (poll-input input)) (return))
                      (lispgb.core:set-buttons machine (input-buttons input))
                      (sync-rtc machine)
                      (lispgb.core:run-frame machine)
                      (present-frame video (lispgb.core:machine-framebuffer machine))
                      (output-audio audio machine)
                      (pace-frame audio))
                  (close-audio audio)))
            (close-video video))))
    (sdl-quit)))
(defun main ()
  (let ((args (uiop:command-line-arguments)))
    (unless (and (= 1 (length args)) (not (and (plusp (length (first args))) (char= #\- (char (first args) 0)))))
      (format *error-output* "使い方: lispgb <ROMファイル>~%")
      (uiop:quit 2))
    (handler-case
        (progn (play-machine (lispgb.core:make-machine (read-rom-file (first args)))) (uiop:quit 0))
      (error (condition) (format *error-output* "実行エラー: ~A~%" condition) (uiop:quit 1)))))
