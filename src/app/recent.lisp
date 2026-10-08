(in-package #:lispgb)
(defun update-recent-list (path paths)
  (let ((unique (remove-duplicates (cons path paths) :test #'string= :from-end t)))
    (subseq unique 0 (min 10 (length unique)))))
(defun read-recent (directory)
  (when directory
    (let ((path (merge-pathnames "recent.txt" directory)))
      (when (probe-file path)
        (handler-case
            (with-open-file (stream path :external-format :utf-8)
              (loop for line = (read-line stream nil) while line when (plusp (length line)) collect line))
          (error (condition) (format *error-output* "警告: 最近使った ROM の一覧を読めません: ~A~%" condition) nil))))))
(defun remember-rom (directory path)
  (when directory
    (handler-case
        (let ((paths (update-recent-list (namestring (truename path)) (read-recent directory))))
          (write-file-atomically (merge-pathnames "recent.txt" directory)
                                (sb-ext:string-to-octets (format nil "~{~A~%~}" paths) :external-format :utf-8)))
      (error (condition) (format *error-output* "警告: 最近使った ROM の一覧を保存できません: ~A~%" condition)))))
