;;; 通常ビルドで3000フレームを実行し、経過実時間から速度を求める。
(with-open-file (stream (uiop:getenv "LISPGB_BENCH_ROM") :element-type '(unsigned-byte 8))
  (let* ((rom (make-array (file-length stream) :element-type '(unsigned-byte 8)))
         (machine (progn (read-sequence rom stream) (lispgb.core:make-machine rom)))
         (start (get-internal-real-time)))
    (dotimes (i 3000) (lispgb.core:run-frame machine))
    (let ((seconds (/ (- (get-internal-real-time) start) (float internal-time-units-per-second))))
      (format t "3000 フレーム: ~,3F 秒、~,2F fps~%" seconds (/ 3000 seconds)))))
