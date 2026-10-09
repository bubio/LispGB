(in-package #:lispgb)

;; キーの物理送信ではなく、実 SDL のイベントキューとアプリの処理を検証する。
(define-sdl-functions
  ("SDL_PushEvent" smoke-push-event sb-alien:int (event sb-alien:system-area-pointer)))
(defun smoke-key (input key)
  (let ((event (make-array +sdl-event-size+ :element-type '(unsigned-byte 8) :initial-element 0)))
    (sb-sys:with-pinned-objects (event)
      (let ((sap (sb-sys:vector-sap event)))
        (setf (sb-sys:sap-ref-32 sap 0) #x300
              (sb-sys:sap-ref-32 sap +sdl-key-offset+) key)
        (assert (= 1 (smoke-push-event sap)))))
    (poll-input input)))

(let* ((rom-path (uiop:getenv "LISPGB_SDL_ROM"))
       (machine (lispgb.core:make-machine (read-file-octets rom-path)))
       (input (make-input))
       (modes (sb-int:get-floating-point-modes)))
  (load-sdl2)
  (unwind-protect
      (progn
        (check-sdl (sdl-init #x21))
        ;; C の呼び出しから戻った後は Lisp 側の例外設定を保つ。
        (assert (equal modes (sb-int:get-floating-point-modes)))
        (let ((video (open-video :scale 2)) (audio nil))
          (unwind-protect
              (progn
                (setf audio (open-audio))
                (assert (plusp (audio-device audio)))
                (dotimes (i 120)
                  (poll-input input)
                  (lispgb.core:run-frame machine)
                  (present-frame video (lispgb.core:machine-framebuffer machine))
                  (output-audio audio machine)
                  (pace-frame audio))
                (assert (member :save (smoke-key input 1073741882)))
                (handle-state-event :save machine rom-path audio)
                (let ((saved (read-file-octets (state-path rom-path))))
                  (lispgb.core:run-frame machine)
                  (assert (member :load (smoke-key input 1073741884)))
                  (handle-state-event :load machine rom-path audio)
                  (assert (equalp saved (lispgb.core:save-state machine)))
                  (assert (zerop (sdl-get-queued-audio-size (audio-device audio)))))
                (smoke-key input 122)
                (assert (member :b (input-buttons input)))
                (assert (member :quit (smoke-key input 27)))
                (format t "SDL 実描画・音声デバイス・入力イベント・保存復元の検証合格~%"))
            (when audio (close-audio audio))
            (close-video video))))
    (sdl-quit)))
