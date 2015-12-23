;;;; -*- Mode: lisp; indent-tabs-mode: nil -*-
;;;
;;; fsbv.lisp --- Tests of foreign structure by value calls.
;;;
;;; Copyright (C) 2011, Liam M. Healy
;;;
;;; Permission is hereby granted, free of charge, to any person
;;; obtaining a copy of this software and associated documentation
;;; files (the "Software"), to deal in the Software without
;;; restriction, including without limitation the rights to use, copy,
;;; modify, merge, publish, distribute, sublicense, and/or sell copies
;;; of the Software, and to permit persons to whom the Software is
;;; furnished to do so, subject to the following conditions:
;;;
;;; The above copyright notice and this permission notice shall be
;;; included in all copies or substantial portions of the Software.
;;;
;;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;;; NONINFRINGEMENT.  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
;;; WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;;; DEALINGS IN THE SOFTWARE.
;;;

(in-package #:cffi-tests)

;; Requires struct.lisp

(defcfun "sumpair" :int
  (p (:struct struct-pair)))

(defcfun "makepair" (:struct struct-pair)
  (condition :bool))

(defcfun "doublepair" (:struct struct-pair)
  (p (:struct struct-pair)))

(defcfun "prodsumpair" :double
  (p (:struct struct-pair+double)))

(defcfun "doublepairdouble" (:struct struct-pair+double)
  (p (:struct struct-pair+double)))

;;; Call struct by value
(deftest fsbv.1
    (sumpair '(1 . 2))
  3)

;;; See lp#1528719
(deftest (fsbv.wfo :expected-to-fail t)
    (with-foreign-object (arg '(:struct struct-pair))
      (convert-into-foreign-memory '(40 . 2) '(:struct struct-pair) arg)
      (sumpair arg))
  42)

;;; Call and return struct by value
(deftest fsbv.2
    (doublepair '(1 . 2))
  (2 . 4))

;;; return struct by value
(deftest (fsbv.makepair.1 :expected-to-fail t)
    (makepair nil)
  (-127 . 43))

(deftest (fsbv.makepair.2 :expected-to-fail t)
    (makepair t)
  (-127 . 42))

;;; Call recursive structure by value
(deftest fsbv.3
    (prodsumpair '(pr (a 4 b 5) dbl 2.5d0))
  22.5d0)

;;; Call and return recursive structure by value
(deftest fsbv.4
    (let ((ans (doublepairdouble '(pr (a 4 b 5) dbl 2.5d0))))
      (values (getf (getf ans 'pr) 'a)
	      (getf (getf ans 'pr) 'b)
	      (getf ans 'dbl)))
  8
  10
  5.0d0)

;;; Typedef fsbv test

(defcfun ("sumpair" sumpair2) :int
  (p struct-pair-typedef1))

(deftest fsbv.5
    (sumpair2 '(1 . 2))
  3)

;;; Test ulonglong on no-long-long implementations.

(defcfun "ullsum" :unsigned-long-long
  (a :unsigned-long-long) (b :unsigned-long-long))

(deftest fsbv.6
    (ullsum #x10DEADBEEF #x2300000000)
  #x33DEADBEEF)

;;; Combine structures by value with a string argument
(defcfun "stringlenpair" (:struct struct-pair)
  (s :string)
  (p (:struct struct-pair)))

(deftest fsbv.7
  (stringlenpair "abc" '(1 . 2))
  (3 . 6))

;;; Combine structures by value with an enum argument
(defcfun "enumpair" (:int)
  (e numeros)
  (p (:struct struct-pair)))

(deftest fsbv.8
  (enumpair :two '(1 . 2))
  5)

;;; returning struct with bitfield member (bug #1474631)
(defbitfield (struct-bitfield :unsigned-int)
  (:a 1)
  (:b 2))

(defcstruct bitfield-struct
  (b struct-bitfield))

(defcfun "structbitfield" (:struct bitfield-struct)
  (x :unsigned-int))

(defctype struct-bitfield-typedef struct-bitfield)

(defcstruct bitfield-struct.2
  (b struct-bitfield-typedef))

(defcfun ("structbitfield" structbitfield.2) (:struct bitfield-struct.2)
  (x :unsigned-int))

;; these would get stuck in an infinite loop previously
(deftest fsbv.struct-bitfield.0
  (structbitfield 0)
  (b nil))

(deftest fsbv.struct-bitfield.1
  (structbitfield 1)
  (b (:a)))

(deftest fsbv.struct-bitfield.2
  (structbitfield 2)
  (b (:b)))

(deftest fsbv.struct-bitfield.3
  (structbitfield.2 2)
  (b (:b)))

