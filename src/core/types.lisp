(in-package #:lispgb.core)

(deftype u8 () '(unsigned-byte 8))
(deftype u16 () '(unsigned-byte 16))
(deftype u32 () '(unsigned-byte 32))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun core-optimize-spec ()
    "コンパイル時の機能指定からコア専用の最適化宣言を返す。"
    (if (member :lispgb-safe *features*)
        '(optimize (speed 1) (safety 1) (debug 2))
        '(optimize (speed 3) (safety 0) (debug 0)))))

(declaim #.(core-optimize-spec))
(declaim (inline bit-set-p set-bit wrap8 wrap16))
(defun bit-set-p (value bit) (logbitp bit value))
(defun set-bit (value bit &optional (setp t))
  (dpb (if setp 1 0) (byte 1 bit) value))
(defun wrap8 (value) (ldb (byte 8 0) value))
(defun wrap16 (value) (ldb (byte 16 0) value))
