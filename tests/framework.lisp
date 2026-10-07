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

(defun run-tests (&key only)
  "全テスト、または ONLY に指定した名前（単体・リスト）を実行し、失敗数を返す。"
  (let ((failures 0)
        (names (if only (if (listp only) only (list only))
                   (sort (loop for name being the hash-keys of *tests* collect name)
                         #'string< :key #'symbol-name))))
    (dolist (name names failures)
      (let ((test (gethash name *tests*))
            (pending (gethash name *pending-tests*))
            (known (gethash name *known-failures*)))
        (handler-case
            (progn
              (unless test (error "未登録のテスト: ~A" name))
              (funcall test)
              (format t "PASS ~A~%" name)
              (when pending
                (format t "警告: ~A: PENDING だが合格: 登録を外すこと~%" name)))
          (error (condition)
            (cond
              ((null test) (incf failures) (format t "FAIL ~A: ~A~%" name condition))
              (pending (format t "PENDING (~A 待ち) ~A: ~A~%" pending name condition))
              (known (format t "KNOWN ~A: ~A — ~A~%" name known condition))
              (t (incf failures) (format t "FAIL ~A: ~A~%" name condition)))))))))
