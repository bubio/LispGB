(in-package #:lispgb.tests)

(deftest rom-inventory-empty-and-incomplete ()
  (let* ((root (asdf:system-relative-pathname "lispgb/tests" "build/rom-inventory-empty/"))
         (file (merge-pathnames "acid2/dmg-acid2.gb" root)))
    (ensure-directories-exist file)
    (unwind-protect
        (progn
          (is (eq :skip (check-rom-inventory :root root :required nil)))
          (is (signals-condition-p 'error (lambda () (check-rom-inventory :root root :required t))))
          (with-open-file (out file :direction :output :element-type '(unsigned-byte 8)
                              :if-exists :supersede) (write-byte 0 out))
          (is (signals-condition-p 'error (lambda () (check-rom-inventory :root root :required nil))))
          (is (signals-condition-p 'error (lambda () (check-rom-inventory :root root :required t)))))
      (when (probe-file file) (delete-file file)))))

(deftest rom-inventory-complete-and-truncated ()
  (let* ((root (asdf:system-relative-pathname "lispgb/tests" "build/rom-inventory-complete/"))
         (names (required-rom-names)))
    (is (= (length names) 81))
    (unwind-protect
        (progn
          (dolist (name names)
            (let ((path (merge-pathnames name root)))
              (ensure-directories-exist path)
              (with-open-file (out path :direction :output :element-type '(unsigned-byte 8)
                                       :if-exists :supersede)
                (dotimes (i #x150) (write-byte 0 out)))))
          (is (eq :complete (check-rom-inventory :root root :required t)))
          (with-open-file (out (merge-pathnames "acid2/dmg-acid2.gb" root)
                               :direction :output :if-exists :supersede))
          (is (signals-condition-p 'error (lambda () (check-rom-inventory :root root :required t)))))
      (dolist (name names) (let ((path (merge-pathnames name root)))
                            (when (probe-file path) (delete-file path)))))))

(deftest rom-fetch-script-regression ()
  ;; Unix の一括実行には通信を置き換えた取得回帰検証も含める。
  ;; Windows は同じ取得スクリプトを Git Bash ラッパーから使用する。
  (when (and (not (uiop:os-windows-p))
             (eq :complete (check-rom-inventory :required nil)))
    (uiop:run-program '("sh" "tests/scripts/fetch-test.sh")
                      :directory (asdf:system-source-directory "lispgb")
                      :output *standard-output* :error-output *error-output*)))
