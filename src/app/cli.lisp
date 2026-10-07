(in-package #:lispgb)
(define-condition usage-error (error)
  ((message :initarg :message :reader usage-message))
  (:report (lambda (condition stream) (write-string (usage-message condition) stream))))
(defstruct cli-options rom headless frames screenshot scale fullscreen shader recent help version)
(defun parse-args (arguments)
  (let ((options (make-cli-options)))
    (labels ((value () (or (pop arguments) (error 'usage-error :message "オプションの値が必要です。"))))
      (loop while arguments for argument = (pop arguments) do
        (cond ((member argument '("--help" "-h") :test #'string=) (setf (cli-options-help options) t))
              ((member argument '("--version" "-v") :test #'string=) (setf (cli-options-version options) t))
              ((string= argument "--recent") (setf (cli-options-recent options) t))
              ((string= argument "--fullscreen") (setf (cli-options-fullscreen options) t))
              ((string= argument "--scale")
               (let ((n (ignore-errors (parse-integer (value)))))
                 (unless (and n (plusp n)) (error 'usage-error :message "拡大率は正の整数で指定してください。"))
                 (setf (cli-options-scale options) (min 8 n))))
              ((string= argument "--shader")
               (let ((kind (value)))
                 (setf (cli-options-shader options)
                       (cond ((string= kind "nearest") :nearest) ((string= kind "smooth") :smooth)
                             (t (error 'usage-error :message "補間方式は nearest / smooth で指定してください。"))))))
              ((string= argument "--headless") (setf (cli-options-headless options) t))
              ((string= argument "--frames")
               (let ((n (ignore-errors (parse-integer (value)))))
                 (unless (and n (plusp n)) (error 'usage-error :message "フレーム数は正の整数で指定してください。"))
                 (setf (cli-options-frames options) n)))
              ((string= argument "--screenshot") (setf (cli-options-screenshot options) (value)))
              ((and (plusp (length argument)) (char= #\- (char argument 0)))
               (error 'usage-error :message (format nil "不明なオプション: ~A" argument)))
              ((cli-options-rom options) (error 'usage-error :message "ROM は1つだけ指定してください。"))
              (t (setf (cli-options-rom options) argument)))))
    (when (or (cli-options-help options) (cli-options-version options) (cli-options-recent options))
      (return-from parse-args options))
    (unless (cli-options-rom options) (error 'usage-error :message "ROM ファイルを指定してください。"))
    (when (and (cli-options-headless options) (not (cli-options-frames options)))
      (error 'usage-error :message "--headless には --frames が必要です。"))
    (when (and (not (cli-options-headless options)) (or (cli-options-frames options) (cli-options-screenshot options)))
      (error 'usage-error :message "--frames と --screenshot は --headless と組み合わせてください。"))
    options))
(defun print-help (&optional (stream *standard-output*))
  (format stream "使い方: lispgb [オプション] <ROMファイル>~%
  -h, --help          この使い方を表示
  -v, --version       バージョンを表示
  --scale N           拡大率（1〜8、既定4）
  --fullscreen        フルスクリーン表示
  --shader KIND       nearest / smooth（既定 nearest）
  --recent            最近使った ROM の一覧
  --headless          ウィンドウ・音声なしで実行
  --frames N          ヘッドレスで実行するフレーム数（必須）
  --screenshot PATH   終了時の画像を BMP で保存

キー操作: 矢印=十字キー、Z=B、X=A、Enter=Start、右Shift=Select
          F1=保存、F3=復元、Esc=終了~%"))
