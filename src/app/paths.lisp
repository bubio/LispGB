(in-package #:lispgb)
(defun save-ram-path (rom-path) (make-pathname :type "sav" :defaults (pathname rom-path)))
(defun state-path (rom-path) (make-pathname :type "state" :defaults (pathname rom-path)))
(defun config-directory (&optional (xdg (uiop:getenv "XDG_CONFIG_HOME"))
                                   (home (user-homedir-pathname))
                                   (platform (if (uiop:os-macosx-p) :macos :linux)))
  "OS の慣習に従う設定と一覧の保存先を返す。"
  (if (eq platform :macos)
      (merge-pathnames "Library/Application Support/LispGB/" home)
      (merge-pathnames "LispGB/"
                      (if (and xdg (plusp (length xdg)))
                          (uiop:ensure-directory-pathname xdg)
                          (merge-pathnames ".config/" home)))))
