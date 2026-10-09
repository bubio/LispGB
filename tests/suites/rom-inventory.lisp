(in-package #:lispgb.tests)

(defun required-rom-names ()
  "取得スクリプトとテストが共用する必須 ROM 一覧を読む。"
  (with-open-file (stream (asdf:system-relative-pathname "lispgb/tests" "tests/rom-manifest.txt")
                          :external-format :utf-8)
    (loop for line = (read-line stream nil) while line
          for text = (string-trim '(#\Space #\Tab #\Return) line)
          when (and (plusp (length text)) (char/= (char text 0) #\#)) collect text)))

(defun check-rom-inventory (&key
                             (root (asdf:system-relative-pathname "lispgb/tests" "tests/roms/"))
                             (required (equal "1" (uiop:getenv "LISPGB_REQUIRE_TEST_ROMS"))))
  "未取得のローカル実行だけはスキップし、一部欠落や CI の未取得は拒否する。"
  (let* ((names (required-rom-names))
         (any-rom (directory (merge-pathnames "**/*.gb*" root))))
    (when (and (not required) (null any-rom))
      (format t "テスト ROM がないため ROM テストをスキップします。~%")
      (return-from check-rom-inventory :skip))
    (let ((missing (loop for name in names for path = (merge-pathnames name root)
                         unless (and (probe-file path)
                                     (with-open-file (stream path :element-type '(unsigned-byte 8))
                                       (>= (file-length stream) #x150)))
                         collect name)))
      (when missing
        (error "必須テスト ROM が未取得または不完全です。scripts/fetch_test_roms を実行してください:~%~{  ~A~%~}"
               missing)))
    :complete))
