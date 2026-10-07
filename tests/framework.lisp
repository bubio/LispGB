(defpackage #:lispgb.tests
  (:use #:cl)
  (:export #:deftest #:is #:run-tests #:register-known-failure #:register-pending))
(in-package #:lispgb.tests)

(defvar *tests* (make-hash-table :test #'eq))
(defvar *known-failures* (make-hash-table :test #'eq))
(defvar *pending-tests* (make-hash-table :test #'eq))

(define-condition assertion-failure (error)
  ((form :initarg :form :reader assertion-form)
   (message :initarg :message :reader assertion-message))
  (:report (lambda (condition stream)
             (format stream "判定失敗: ~S~@[ — ~A~]"
                     (assertion-form condition) (assertion-message condition)))))

(defmacro deftest (name () &body body)
  "名前付きテストを登録する。再評価すると同名のテストを置き換える。"
  `(setf (gethash ',name *tests*) (lambda () ,@body)))

(defmacro is (form &optional message)
  "FORM を一度だけ評価し、偽なら式を含む条件を通知する。"
  `(unless ,form
     (error 'assertion-failure :form ',form :message ,message)))

(defun register-known-failure (name reason)
  (setf (gethash name *known-failures*) reason))

(defun register-pending (name until-task)
  (setf (gethash name *pending-tests*) until-task))

(defun test-suite-name (name)
  (let* ((text (symbol-name name)) (slash (position #\/ text)))
    (cond (slash (subseq text 0 slash))
          ((search "ACID2" text) "ACID2") (t "UNIT"))))
(defun run-tests (&key only)
  "スイートごとの結果と件数を表示し、不合格数を返す。"
  (let ((failures 0) (passed 0) (known-count 0) (pending-count 0) (last-suite nil)
        (names (if only (if (listp only) only (list only))
                   (sort (loop for name being the hash-keys of *tests* collect name)
                         #'string< :key (lambda (name) (concatenate 'string (test-suite-name name) "/" (symbol-name name)))))))
    (dolist (name names)
      (let ((test (gethash name *tests*)) (pending (gethash name *pending-tests*))
            (known (gethash name *known-failures*)) (suite (test-suite-name name)))
        (unless (equal last-suite suite) (format t "~%[~A]~%" suite) (setf last-suite suite))
        (handler-case
            (progn
              (unless test (error "未登録のテスト: ~A" name))
              (funcall test) (incf passed)
              (format t "PASS ~A~%" name)
              (when pending (format t "警告: ~A: PENDING だが合格: 登録を外すこと~%" name)))
          (error (condition)
            (cond
              ((null test) (incf failures) (format t "FAIL ~A: ~A~%" name condition))
              (pending (incf pending-count) (format t "PENDING (~A 待ち) ~A: ~A~%" pending name condition))
              (known (incf known-count) (format t "KNOWN ~A: ~A — ~A~%" name known condition))
              (t (incf failures) (format t "FAIL ~A: ~A~%" name condition)))))))
    (format t "~%合格: ~D / 不合格: ~D / 既知の不合格: ~D / 実装待ち: ~D~%" passed failures known-count pending-count)
    failures))
