(in-package #:lispgb)
(defun save-ram-path (rom-path) (make-pathname :type "sav" :defaults (pathname rom-path)))
(defun state-path (rom-path) (make-pathname :type "state" :defaults (pathname rom-path)))
(defun config-directory (&optional (xdg (uiop:getenv "XDG_CONFIG_HOME"))
                                   (home (user-homedir-pathname))
                                   (platform (cond ((uiop:os-windows-p) :windows)
                                                   ((uiop:os-macosx-p) :macos)
                                                   (t :linux)))
                                   (appdata (uiop:getenv "APPDATA")))
  "OS の慣習に従う設定と一覧の保存先を返す。"
  (case platform
    (:windows (merge-pathnames "LispGB/"
                (if (and appdata (plusp (length appdata)))
                    (uiop:ensure-directory-pathname appdata)
                    (merge-pathnames "AppData/Roaming/" home))))
    (:macos (merge-pathnames "Library/Application Support/LispGB/" home))
    (otherwise (merge-pathnames "LispGB/"
                      (if (and xdg (plusp (length xdg)))
                          (uiop:ensure-directory-pathname xdg)
                          (merge-pathnames ".config/" home))))))
