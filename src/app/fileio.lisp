(in-package #:lispgb)

(defun read-file-octets (path)
  (handler-case
      (with-open-file (stream path :direction :input :element-type '(unsigned-byte 8))
        (let ((bytes (make-array (file-length stream) :element-type '(unsigned-byte 8))))
          (unless (= (length bytes) (read-sequence bytes stream)) (error "読み込みが途中で終わりました。"))
          bytes))
    (error (condition) (error "ファイルを読み込めません: ~A（~A）" path condition))))
(defun write-file-atomically (path octets)
  "同じディレクトリの一時ファイルを書き終えてから置き換える。"
  (let ((temporary (pathname (concatenate 'string (namestring path) ".tmp"))))
    (unwind-protect
        (handler-case
            (progn
              (with-open-file (stream temporary :direction :output :element-type '(unsigned-byte 8)
                                     :if-exists :supersede :if-does-not-exist :create)
                (write-sequence octets stream) (finish-output stream))
              (uiop:rename-file-overwriting-target temporary path))
          (error (condition) (error "ファイルを保存できません: ~A（~A）" path condition)))
      (when (probe-file temporary) (ignore-errors (delete-file temporary)))))
  path)
