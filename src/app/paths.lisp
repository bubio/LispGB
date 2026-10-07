(in-package #:lispgb)
(defun save-ram-path (rom-path) (make-pathname :type "sav" :defaults (pathname rom-path)))
(defun state-path (rom-path) (make-pathname :type "state" :defaults (pathname rom-path)))
