(defpackage #:lispgb.core
  (:use #:cl)
  (:export #:make-machine #:run-frame #:machine-framebuffer #:machine-serial-log
           #:machine-cpu-registers #:machine-ld-b-b-hit-p #:machine-read-byte
           #:set-buttons #:drain-audio #:save-state #:load-state #:savestate-size
           #:savestate-error #:savestate-error-reason))
