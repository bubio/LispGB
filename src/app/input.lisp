(in-package #:lispgb)

(defparameter +button-keys+
  '((1073741903 . :right) (1073741904 . :left) (1073741906 . :up) (1073741905 . :down)
    (122 . :b) (120 . :a) (13 . :start) (1073742053 . :select)))
(defstruct input
  (buttons nil) (event (make-array +sdl-event-size+ :element-type '(unsigned-byte 8) :initial-element 0)))
(defun handle-key (input key pressed repeat)
  (let ((button (cdr (assoc key +button-keys+))))
    (cond (button (if pressed (pushnew button (input-buttons input))
                     (setf (input-buttons input) (remove button (input-buttons input)))) nil)
          ((and pressed (not repeat)) (case key (27 :quit) (1073741882 :save) (1073741884 :load))))))
(defun poll-input (input)
  (let ((events nil) (buffer (input-event input)))
    (sb-sys:with-pinned-objects (buffer)
      (let ((sap (sb-sys:vector-sap buffer)))
        (loop while (= 1 (sdl-poll-event sap)) do
          (let* ((type (sb-sys:sap-ref-32 sap 0))
                 (event (case type
                          (#x100 :quit)
                          (#x200 (when (= 13 (sb-sys:sap-ref-8 sap 12)) (setf (input-buttons input) nil)) nil)
                          ((#x300 #x301)
                           (handle-key input (sb-sys:sap-ref-32 sap +sdl-key-offset+) (= type #x300)
                                       (plusp (sb-sys:sap-ref-8 sap +sdl-repeat-offset+)))))))
            (when event (push event events))))))
    (nreverse events)))
