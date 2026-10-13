#!/usr/bin/env sbcl --script
;; <xbar.title>Mac Battery Control</xbar.title>
;; <xbar.author>Hraban Luyat</xbar.author>
;; <xbar.author.github>hraban</xbar.author.github>
;; <xbar.desc>Control your Mac laptop’s maximum battery charge to improve its longevity</xbar.desc>
;; <xbar.var>boolean(DEBUG=false): Verbose output</xbar.var>
;; <xbar.dependencies>lisp</xbar.dependencies>

;; Copyright © 2024  Hraban Luyat
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU Affero General Public License as published
;; by the Free Software Foundation, version 3 of the License.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU Affero General Public License for more details.
;;
;; You should have received a copy of the GNU Affero General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

(setf *compile-verbose* NIL)
(setf *trace-output* *error-output*)

(require "asdf")
(require "uiop")

(asdf:load-system "cl-interpol")
(asdf:load-system "cl-ppcre")
(asdf:load-system "inferior-shell")
(asdf:load-system "trivia")

(defpackage #:battery
  (:use #:cl)
  (:local-nicknames (#:sh #:inferior-shell)))

(in-package #:battery)

(named-readtables:in-readtable :interpol-syntax)

(defvar *me* "@self@")

(defun debugp ()
  (string= "true" (uiop:getenv "DEBUG")))

(defun sh (&rest args)
  (apply #'sh:run `(,@args :show ,(debugp))))

(defun sh/ss (&rest args)
  (apply #'sh `(,@args :output (:string :stripped t))))

(defun smc-read ()
  (sh/ss '(toggle-charging)))

(defun parse-smc-val (smc-val)
  (trivia:match smc-val
    ("on" "⚡")
    ("off" "🔌")
    (_ "❓")))

(defun charging-state ()
  (parse-smc-val (smc-read)))

(defun println (s)
  (format T "~A~%" s))

(defun boolstr (b)
  (if b "true" "false"))

(defun print-menu ()
  (println (charging-state))
  (println "---")
  (println #?"⚡ | shell=${*me*} | param1=on | terminal=${(boolstr (debugp))} | refresh=true")
  (println #?"🔌 | shell=${*me*} | param1=off | terminal=${(boolstr (debugp))} | refresh=true"))

(defun main ()
  (trivia:match (uiop:command-line-arguments)
    (()
     (print-menu))
    ((list "on")
     (sh '(sudo toggle-charging on))
     (print-menu))
    ((list "off")
     (sh '(sudo toggle-charging off))
     (print-menu))))

(main)
