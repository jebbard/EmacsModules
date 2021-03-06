;;; moin-ert-tests.el --- Automatic unit tests of moin mode

;; Copyright (C) 2017 Jens Ebert

;; Author: Jens Ebert <jensebert@gmx.net>
;; Maintainer: Jens Ebert <jensebert@gmx.net>
;; Created: 26 April 2017
;; Keywords: wiki editing

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Automatic unit tests of moin mode

;;; Code

(require 'ert)

;; ==================================================
;; Constants
(defconst test-moin-folder "./testdata/"
  "The test data folder")

;; ==================================================
;; Test general helper functions

(defun test-moin--execute-on-file (filePath action args)
  "Run an action on a temp buffer whose content is provided by a file. This function
sets point to the beginning of the test buffer."
  (with-temp-buffer
    (insert-file-contents (concat test-moin-folder filePath))
    (beginning-of-buffer)
    (funcall action args)))


(defun check-func-at-point(func initial-text initial-point expected-point &optional expected-buffer-text region-size args expected-return-value)
  "Inserts the given text into a temporary buffer, then sets point to a specific
position, optionally selects a region, and finally calls an arbitrary command or
function with arbitrary arguments. It expects the buffer content to be as given
by expected-buffer-text - or - if that is nil, the same as the initial-text, and
the new point at the given expected-point."
  (let (actual-return-value)
    (with-temp-buffer
      (moin-mode)
      (insert initial-text)
      (goto-char initial-point)

      ;; Set the region before executing the func
      (if region-size
	  (progn
	    (set-mark-command nil)
	    (forward-char region-size)))

      (if args
	  (setq actual-return-value (funcall func args))
	(setq actual-return-value (funcall func)))


      (if expected-return-value
	  (should (equal expected-return-value actual-return-value)))

      (if expected-buffer-text
	  (should (equal expected-buffer-text (buffer-string)))
	(should (equal initial-text (buffer-string))))

      (if expected-point
      	  (should (equal expected-point (point)))
      	(should (equal initial-point (point)))))))


(defun check-read-only-func-at-point(func text initial-point &optional expected-return-value args expected-point region-size)
  "Inserts the given text into a temporary buffer, then sets point to a specific
initial-point, optionally selects a region, and finally calls an arbitrary read-only
function with arbitrary arguments. It expects the buffer content to be unchanged after
the function invocation and the new point at the given expected-point. Furthermore, it
checks the function return value against the expected return value."
  (let (actual-return-value)
    (with-temp-buffer
      (moin-mode)
      (insert text)
      (goto-char initial-point)

      ;; Set the region before executing the func
      (if region-size
	  (progn
	    (set-mark-command nil)
	    (forward-char region-size)))

      (if args
	  (setq actual-return-value (funcall func args))
	(setq actual-return-value (funcall func)))

      (if expected-return-value
	  (should (equal expected-return-value actual-return-value)))

      (should (equal text (buffer-string)))

      (if expected-point
	  (should (equal expected-point (point)))
	(should (equal initial-point (point)))))))


(defun check-func-at-point-throws-error(func initial-text initial-point expected-error-type
					     &optional region-size args)
  "Inserts the given initial-text into a temporary buffer, then sets point to
a specific initial-point, optionally selects a region of size region-size, and
finally calls an arbitrary function func with arbirary arguments args. It expects
the expected-error-type to be thrown."
  (with-temp-buffer
    (insert initial-text)
    (goto-char initial-point)

    ;; Set the region before executing the command
    (if region-size
	(progn
	  (set-mark-command nil)
	  (forward-char region-size)))
    
    (should-error
     (if args
	 (funcall func args)
       (funcall func))
     :type expected-error-type)))


;; ==================================================
;; Testing syntax highlighting functions

;; TODO

;; ==================================================
;; Testing formatting functions

(ert-deftest test-moin-command-format-bold()
  "Tests `moin-command-format-bold'"
  (test-moin--check-formatting "" 'moin-command-format-bold moin-const-format-bold 1 1)
  (test-moin--check-formatting "bold" 'moin-command-format-bold moin-const-format-bold 1 5)
  (test-moin--check-formatting "bold" 'moin-command-format-bold moin-const-format-bold 2 4))


(ert-deftest test-moin-command-format-italic()
  "Tests `moin-command-format-italic'"
  (test-moin--check-formatting "" 'moin-command-format-italic moin-const-format-italic 1 1)
  (test-moin--check-formatting "italic" 'moin-command-format-italic moin-const-format-italic 1 7)
  (test-moin--check-formatting "italic" 'moin-command-format-italic moin-const-format-italic 2 5))


(ert-deftest test-moin-command-format-underline()
  "Tests `moin-command-format-underline'"
  (test-moin--check-formatting "" 'moin-command-format-underline moin-const-format-underline 1 1)
  (test-moin--check-formatting "underline" 'moin-command-format-underline moin-const-format-underline 1 9)
  (test-moin--check-formatting "underline" 'moin-command-format-underline moin-const-format-underline 2 8))


(defun test-moin--check-formatting(text command markup formatting-start-point formatting-end-point)
  (with-temp-buffer
    (insert text)

    ;; Set the region
    (if (not (eq formatting-start-point formatting-end-point))
	(progn
	  (goto-char formatting-start-point)
	  (set-mark-command nil)
	  (goto-char formatting-end-point)))

    (setq markup-len (length markup))
    (setq new-formatting-end-point (+ formatting-end-point markup-len))
    
    (funcall command)
    
    (should (equal new-formatting-end-point (point)))
    ;; Check text before formatted text - must be unchanged
    (should (equal (substring text 0 (- formatting-start-point 1))
		   (buffer-substring-no-properties 1 formatting-start-point)))
    ;; Check markup start
    (should (equal markup (buffer-substring-no-properties
			   formatting-start-point (+ formatting-start-point markup-len))))
    ;; Check formatted text (within markup) - must be unchanged
    (should (equal (substring text (- formatting-start-point 1)
			      (- formatting-end-point 1)) (buffer-substring-no-properties
			   (+ formatting-start-point markup-len) new-formatting-end-point)))
    ;; Check markup end
    (should (equal markup (buffer-substring-no-properties
			   new-formatting-end-point (+ new-formatting-end-point markup-len))))
    ;; Check text after formatted text - must be unchanged
    (should (equal (substring text (- formatting-end-point 1))
		   (buffer-substring-no-properties (+ new-formatting-end-point markup-len) (point-at-eol))))))


(ert-deftest test-moin-command-format-bold-error()
  "Tests proper error handling of `moin-command-format-bold'"
  (check-func-at-point-throws-error 'moin-command-format-bold
					     "Text\narbitrary other test text" 2 'user-error 5)
  (check-func-at-point-throws-error 'moin-command-format-bold
					     "Text\narbitrary other test text" 3 'user-error 7))


(ert-deftest test-moin-command-format-italic-error()
  "Tests proper error handling of `moin-command-format-italic'"
  (check-func-at-point-throws-error 'moin-command-format-italic
					     "Text\narbitrary other test text" 2 'user-error 5)
  (check-func-at-point-throws-error 'moin-command-format-italic
					     "Text\narbitrary other test text" 3 'user-error 7))


(ert-deftest test-moin-command-format-underline-error()
  "Tests proper error handling of `moin-command-format-underline'"
  (check-func-at-point-throws-error 'moin-command-format-underline
					     "Text\narbitrary other test text" 2 'user-error 5)
  (check-func-at-point-throws-error 'moin-command-format-underline
					     "Text\narbitrary other test text" 3 'user-error 7))


;; ==================================================
;; Testing heading functions


(ert-deftest test-moin-is-on-heading-p-when-on-heading-line ()
  "`moin-is-in-heading-p' must return t when point is on a heading line, even if the
end of the heading line is malformed."
  (test-moin--execute-on-heading 'moin-is-on-heading-p "= Heading 1 =" t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "== Heading 2 " t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "=== Heading 3" t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "==== Heading 4 =====" t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "===== Heading 5 =====" t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "===== Hallo =====" t))


(ert-deftest test-moin-is-on-heading-p-when-not-on-heading-line ()
  "`moin-is-in-heading-p' must return nil when point is not on a heading line, especially
when the heading is of a level bigger than 5."
  (test-moin--execute-on-heading 'moin-is-on-heading-p "Heading 1 =" nil)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "" nil)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "	 sdf	" nil)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "		" nil)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "====== No Heading anymore =====" nil)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "==Not a Heading ==" nil))


(ert-deftest test-moin--heading-determine-content ()
  "`moin--heading-determine-content' must return the correct heading text, even if the 
heading is malformed"
  (test-moin--execute-on-heading 'moin--heading-determine-content "= Heading 1 =" "Heading 1")
  (test-moin--execute-on-heading 'moin--heading-determine-content "== Heading 2 " "Heading 2")
  (test-moin--execute-on-heading 'moin--heading-determine-content "=== Heading 3 =" "Heading 3")
  (test-moin--execute-on-heading 'moin--heading-determine-content "==== Heading 4 =====" "Heading 4")
  (test-moin--execute-on-heading 'moin--heading-determine-content "===== Heading 5 =====" "Heading 5"))


(ert-deftest test-moin--heading-determine-level ()
  "`moin--heading-determine-level' must return the correct heading level, even if the 
heading is malformed"
  (test-moin--execute-on-heading 'moin--heading-determine-level "= Heading 1 =" 1)
  (test-moin--execute-on-heading 'moin--heading-determine-level "== Heading 2 " 2)
  (test-moin--execute-on-heading 'moin--heading-determine-level "=== Heading 3 =" 3)
  (test-moin--execute-on-heading 'moin--heading-determine-level "==== Heading 4 =====" 4)
  (test-moin--execute-on-heading 'moin--heading-determine-level "===== Heading 5 =====" 5))


(ert-deftest test-moin--heading-determine-section-level ()
  "`moin--heading-determine-section-level' must return the correct heading level, even if the 
heading is malformed"
  (test-moin--execute-on-heading 'moin--heading-determine-section-level "= Heading 1 =" 1)
  (test-moin--execute-on-heading 'moin--heading-determine-section-level "== Heading 2\nasdasdasd\n\n\n asdasd " 2)
  (test-moin--execute-on-heading 'moin--heading-determine-section-level "=== Heading 3 =\n\n\n\ntextextext\n\ntexttext" 3)
  (test-moin--execute-on-heading 'moin--heading-determine-section-level "==== Heading 4 =====" 4)
  (test-moin--execute-on-heading 'moin--heading-determine-section-level "===== Heading 5 =====" 5))


(defun test-moin--execute-on-heading (function text expected-return)
  "Calls any given function on all characters of a text that is considered to be a heading,
and checks its return value against an expected return value."
  (with-temp-buffer
    (moin-mode)
    (insert text)
    (beginning-of-line)
    (while (not (eolp))
      (setq point-before (point))
      (should (equal expected-return (funcall function)))
      (should (equal point-before (point)))
      (forward-char 1))))


(ert-deftest test-moin--heading-determine-section-level-no-heading ()
  "`moin--heading-determine-section-level' must return 0 if currently in a section
without a heading before."
  (test-moin--determine-section-level-no-heading "" 1)
  (test-moin--determine-section-level-no-heading "Any text" 1)
  (test-moin--determine-section-level-no-heading "Any text" 3)
  (test-moin--determine-section-level-no-heading "Any text" 4)
  (test-moin--determine-section-level-no-heading "Any text\n= Heading =" 5))


(defun test-moin--determine-section-level-no-heading (text point-before)
  (with-temp-buffer
    (moin-mode)
    (insert text)
    (goto-char point-before)
    (should (equal 0 (moin--heading-determine-section-level)))
    (should (equal point-before (point)))))


(ert-deftest test-moin--heading-create ()
  "Tests `moin--heading-create'."
  (test-moin--heading-create 1 "hallo")
  (test-moin--heading-create 2 "Text ")
  (test-moin--heading-create 3 ""))


(defun test-moin--heading-create (level text)
  (with-temp-buffer
    (setq expected-prefix (concat (make-string level ?=) " "))
    (setq expected-suffix (concat " " (make-string level ?=)))
    (setq text-len (length text))
    
    (moin-mode)
    (moin--heading-create level text)
    (should (equal (+ level text-len 2) (point)))
    (beginning-of-line)
    ;; Expect heading start markup
    (should (equal expected-prefix (buffer-substring-no-properties 1 (+ level 2))))
    ;; Expect heading text
    (if text
	(should (equal text (buffer-substring-no-properties (+ level 2) (+ level text-len 2)))))
    ;; Expect heading end markup
    (should (equal expected-suffix (buffer-substring-no-properties
				    (+ level text-len 2) (+ level level text-len 3))))))


(ert-deftest test-moin--heading-fix ()
  "`moin--heading-fix' must fix any malformed and non-malformed heading prefix or suffix"
  (test-moin--check-heading-fix "" "Heading 1" " =" "=" 1)
  (test-moin--check-heading-fix " " "Heading 2" " " "==" 2)
  (test-moin--check-heading-fix "== " "Heading 3" " =" "===" 3)
  (test-moin--check-heading-fix "==== " "Heading 4" " =====" "====" 4)
  (test-moin--check-heading-fix "===== " "Heading 5" " =====" "=====" 5)
  (test-moin--check-heading-fix "=== " "Heading 5" "=====" "=====" 5)
  (test-moin--check-heading-fix "===== " "Heading 5= asdasd" " = =   == =	=" "=====" 5))


(defun test-moin--check-heading-fix(prefix text suffix correct-suffix level)
  (with-temp-buffer
    (moin-mode)
    (insert (concat prefix text suffix))
    (beginning-of-line)
    (moin--heading-fix level)
    (beginning-of-line)
    (should (looking-at (concat correct-suffix " " text " " correct-suffix)))))


(ert-deftest test-moin-command-meta-return ()
  "Checks `moin-command-meta-return' for headings"
  ;; issuing the command at the end of a heading line
  (check-func-at-point 'moin-command-meta-return
				"= Heading 1 =" 14 17 "= Heading 1 =\n=  =\n")
  (check-func-at-point 'moin-command-meta-return
				"= Heading 1 =" 13 17 "= Heading 1 =\n=  =\n")
  (check-func-at-point 'moin-command-meta-return
				"== Heading 2 ==" 13 20 "== Heading 2 ==\n==  ==\n")
  ;; issuing the command within the prefix,
  ;; but not directly at the beginning of a heading line, before any text
  (check-func-at-point 'moin-command-meta-return
				"===== Heading 5 = = =" 4 29 "===== Heading 5 = = =\n=====  =====\n")
  (check-func-at-point 'moin-command-meta-return
				"== Heading 2" 4 17 "== Heading 2\n==  ==\n")
  ;; issuing the command at the beginning of a heading line
  (check-func-at-point 'moin-command-meta-return
				"=== Heading 3 " 1 5 "===  ===\n=== Heading 3 ")
  ;; issuing the command within the heading text
  (check-func-at-point 'moin-command-meta-return
				"= Heading 1 =" 4 17 "= H =\n= eading 1 =\n")
  (check-func-at-point 'moin-command-meta-return
				"== Heading 2 ==" 11 20 "== Heading ==\n==  2 ==\n")
  ;; issuing the command somewhere arbitrary behind a previous heading
  (check-func-at-point 'moin-command-meta-return
      "== Heading 2 ==\nblindtext\nother text" 22 26 "== Heading 2 ==\nblind\n==  ==\ntext\nother text")
  ;; issuing the command before any other heading
  (check-func-at-point 'moin-command-meta-return
	   "Text before heading\n== Heading 2 ==" 14 17 "Text before h\n=  =\neading\n== Heading 2 ==")
  (check-func-at-point 'moin-command-meta-return
          "Text before heading" 2 5 "T\n=  =\next before heading")
  ;; issuing the command at the beginning of the buffer, it should not appear on the
  ;; next line, but on the first line
  (check-func-at-point 'moin-command-meta-return
	  "" 1 3 "=  =\n")
  (check-func-at-point 'moin-command-meta-return
	  "\nHallo" 1 3 "=  =\n\nHallo"))


(ert-deftest test-moin-command-insert-heading-respect-content()
  "Checks `moin-command-insert-heading-respect-content'"
  ;; Check the behaviour in case the current section has no sub-headings, and might
  ;; have contents and siblings
  (check-func-at-point 'moin-command-insert-heading-respect-content
					      "= Heading 1 =" 14 17 "= Heading 1 =\n=  =\n")
  (check-func-at-point 'moin-command-insert-heading-respect-content
					      "= Heading 1 =\n\nAny text behind\nother text\n\n\n" 10 47
					      "= Heading 1 =\n\nAny text behind\nother text\n\n\n=  =\n")
  (check-func-at-point 'moin-command-insert-heading-respect-content
					      "= Heading 1.1 =\n= Heading 1.2 =\n" 5 19
					      "= Heading 1.1 =\n=  =\n= Heading 1.2 =\n")
  (check-func-at-point 'moin-command-insert-heading-respect-content
      "= Heading 1.1 =\nAny Text here and there\n\nAnd another line of text\n= Heading 1.2 =\n" 3 69
      "= Heading 1.1 =\nAny Text here and there\n\nAnd another line of text\n=  =\n= Heading 1.2 =\n")
  
  ;; Check the behaviour in case the current section has multiple sub-headings and a
  ;; sibling heading afterwards, and point is somewhere between the first character of the heading
  ;; and the first character of the next child heading
  (check-func-at-point 'moin-command-insert-heading-respect-content
   "== Heading 2.1 ==\n\nAny text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===\n== Heading 2.2 ==" 12 81
   "== Heading 2.1 ==\n\nAny text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===\n==  ==\n== Heading 2.2 ==")
  (check-func-at-point 'moin-command-insert-heading-respect-content
   "= Heading 1.1 =\nAny text\n== Heading 2.1 ==\nany further text\n== Heading 2.2 ==\nText Text Blindtext\n\n= Heading 1.2 =" 21 102
   "= Heading 1.1 =\nAny text\n== Heading 2.1 ==\nany further text\n== Heading 2.2 ==\nText Text Blindtext\n\n=  =\n= Heading 1.2 =")

  ;; Check the behaviour in case the current section has multiple sub-headings, but no
  ;; sibling heading afterwards, and point is somewhere between the first character of the heading
  ;; and the first character of the next child heading
  (check-func-at-point 'moin-command-insert-heading-respect-content
   "== Heading 2.1 ==\n\nAny text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===" 12 81
   "== Heading 2.1 ==\n\nAny text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===\n==  ==\n")
  (check-func-at-point 'moin-command-insert-heading-respect-content
   "= Heading 1.1 =\nAny text\n== Heading 2.1 ==\nany further text\n== Heading 2.2 ==\nText Text Blindtext\n\n" 21 102
   "= Heading 1.1 =\nAny text\n== Heading 2.1 ==\nany further text\n== Heading 2.2 ==\nText Text Blindtext\n\n=  =\n")

  ;; Check the behaviour in case point is at the beginning of a heading line
  (check-func-at-point 'moin-command-insert-heading-respect-content
  				"= Heading 1 =" 1 3 "=  =\n= Heading 1 =")
  (check-func-at-point 'moin-command-insert-heading-respect-content
   "First text\n== Heading 2 ==\n\nAny subtree text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===" 12 15
   "First text\n==  ==\n== Heading 2 ==\n\nAny subtree text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===")
  
  ;; Check the behaviour in case point is before the first heading (if any at all)
  (check-func-at-point 'moin-command-insert-heading-respect-content
				"" 1 3 "=  =\n")
  (check-func-at-point 'moin-command-insert-heading-respect-content
				"Text" 3 8 "Text\n=  =\n")
  (check-func-at-point 'moin-command-insert-heading-respect-content
				"\n\nText\nOther Text\nYetanothertext\n\n\n" 10 38
				"\n\nText\nOther Text\nYetanothertext\n\n\n=  =\n")
  (check-func-at-point 'moin-command-insert-heading-respect-content
   "First text\n== Heading 2 ==\n\nAny subtree text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===" 6 15
   "First text\n==  ==\n== Heading 2 ==\n\nAny subtree text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ==="))


(ert-deftest test-moin--demote-heading-wo-subtree()
  "Checks `moin-command-meta-right' for headings."
  (check-func-at-point 'moin-command-meta-right "= Heading 1 =" 1 2 "== Heading 1 ==")
  (check-func-at-point 'moin-command-meta-right "=  =" 3 4 "==  ==")
  (check-func-at-point 'moin-command-meta-right "Anytext before\n== Heading 2 ==\nAny text behind"
		       23 24 "Anytext before\n=== Heading 2 ===\nAny text behind")
  (check-func-at-point 'moin-command-meta-right "==== H ====" 12 13 "===== H =====")
  (check-func-at-point 'moin-command-meta-right
      "Anytext before\n=== Heading 3 ===\nAny text behind\n==== H4.1 ====\nsubtext\n==== H4.2 ====\n"
      18 19
      "Anytext before\n==== Heading 3 ====\nAny text behind\n==== H4.1 ====\nsubtext\n==== H4.2 ====\n")
  (check-func-at-point 'moin-command-meta-right "==== Hallo ====" 8 9 "===== Hallo =====")
  (check-func-at-point 'moin-command-meta-right "==== Heading 1 ====" 10 11 "===== Heading 1 ====="))


(ert-deftest test-moin--demote-heading-wo-subtree-error()
  "Checks `moin-command-meta-right' for headings in error situations."
  ;; Cannot demote further
  (check-func-at-point-throws-error 'moin-command-meta-right
   				    "===== Hallo =====" 8 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-right
   				    "===== =====" 1 'user-error)
  ;; Not supported for active mark
  (check-func-at-point-throws-error 'moin-command-meta-right
   				    "=== Hallo ===" 6 'user-error 3))


(ert-deftest test-moin--promote-heading-wo-subtree()
  "Checks `moin-command-meta-left' for headings."
  (check-func-at-point 'moin-command-meta-left "== Heading 2 ==" 1 1 "= Heading 2 =")
  (check-func-at-point 'moin-command-meta-left "===  ===" 3 2 "==  ==")
  (check-func-at-point 'moin-command-meta-left "Anytext before\n== Heading 2 ==\nAny text behind"
  		       23 22 "Anytext before\n= Heading 2 =\nAny text behind")
  (check-func-at-point 'moin-command-meta-left "=== H ===" 10 8 "== H ==")
  (check-func-at-point 'moin-command-meta-left
      "Anytext before\n=== Heading 3 ===\nAny text behind\n==== H4.1 ====\nsubtext\n==== H4.2 ====\n"
      18 17
      "Anytext before\n== Heading 3 ==\nAny text behind\n==== H4.1 ====\nsubtext\n==== H4.2 ====\n")
  (check-func-at-point 'moin-command-meta-left "==== Hallo ====" 8 7 "=== Hallo ===")
  (check-func-at-point 'moin-command-meta-left "==== Heading 1 ====" 10 9 "=== Heading 1 ==="))


(ert-deftest test-moin--promote-heading-wo-subtree-error()
  "Checks `moin-command-meta-left' for headings in error situations."
  ;; Cannot demote further
  (check-func-at-point-throws-error 'moin-command-meta-left
   				    "= Hallo =" 8 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-left
   				    "= =" 1 'user-error)
  ;; Not supported for active mark
  (check-func-at-point-throws-error 'moin-command-meta-left
   				    "=== Hallo ===" 6 'user-error 3))


(ert-deftest test-moin--demote-heading-with-subtree()
  "Checks `moin-command-meta-shift-right' for headings."
  ;; Headings without sub-headings
  (check-func-at-point 'moin-command-meta-shift-right "= Heading 1 =" 1 2 "== Heading 1 ==")
  (check-func-at-point 'moin-command-meta-shift-right "= Heading 1 =\n" 1 2 "== Heading 1 ==\n")
  (check-func-at-point 'moin-command-meta-shift-right "=  =" 3 4 "==  ==")
  (check-func-at-point 'moin-command-meta-shift-right "==== Hallo ====" 8 9 "===== Hallo =====")
  (check-func-at-point 'moin-command-meta-shift-right "==== Heading 1 ====" 10 11 "===== Heading 1 =====")
  (check-func-at-point 'moin-command-meta-shift-right "Anytext before\n== Heading 2 ==\nAny text behind"
  		       23 24 "Anytext before\n=== Heading 2 ===\nAny text behind")
  (check-func-at-point 'moin-command-meta-shift-right "==== H ====" 12 13 "===== H =====")
  ;; With multiple, single-level sub-headings
  (check-func-at-point 'moin-command-meta-shift-right
      "Anytext before\n=== Heading 3 ===\nAny text behind\n==== H4.1 ====\nsubtext\n==== H4.2 ====\n"
      18 19
      "Anytext before\n==== Heading 3 ====\nAny text behind\n===== H4.1 =====\nsubtext\n===== H4.2 =====\n")
  ;; With multiple, multi-level sub-headings
  (check-func-at-point 'moin-command-meta-shift-right
      "Anytext before\n= Heading 1 =\nAny text behind\n== H2.1 ==\nsubtext\n\n=== H3.1 ===\nsubtext\n=== H3.2 ===\nAny \nsub \ntext\n== H2.2 ==\nHallo"
      29 30
      "Anytext before\n== Heading 1 ==\nAny text behind\n=== H2.1 ===\nsubtext\n\n==== H3.1 ====\nsubtext\n==== H3.2 ====\nAny \nsub \ntext\n=== H2.2 ===\nHallo")
    ;; With multiple, multi-level sub-headings, and sibling headings
  (check-func-at-point 'moin-command-meta-shift-right
      "Anytext before\n= Heading 1 =\nAny text behind\n== H2.1 ==\nsubtext\n\n=== H3.1 ===\nsubtext\n=== H3.2 ===\nAny \nsub \ntext\n== H2.2 ==\nHallo\n= Sibling Heading 1 =\nAny text behind\n== SH2.1 ==\nsubtext\n= Sibling Heading 2 =\n"
      29 30
      "Anytext before\n== Heading 1 ==\nAny text behind\n=== H2.1 ===\nsubtext\n\n==== H3.1 ====\nsubtext\n==== H3.2 ====\nAny \nsub \ntext\n=== H2.2 ===\nHallo\n= Sibling Heading 1 =\nAny text behind\n== SH2.1 ==\nsubtext\n= Sibling Heading 2 =\n")
    (check-func-at-point 'moin-command-meta-shift-right
      "Anytext before\n= Heading 1 =\nAny text behind\n== H2.1 ==\nsubtext\n\n=== H3.1 ===\nsubtext\n=== H3.2 ===\nAny \nsub \ntext\n== H2.2 ==\nHallo\n= Sibling Heading 1 =\nAny text behind\n== SH2.1 ==\nsubtext\n= Sibling Heading 2 =\n"
      136 137
      "Anytext before\n= Heading 1 =\nAny text behind\n== H2.1 ==\nsubtext\n\n=== H3.1 ===\nsubtext\n=== H3.2 ===\nAny \nsub \ntext\n== H2.2 ==\nHallo\n== Sibling Heading 1 ==\nAny text behind\n=== SH2.1 ===\nsubtext\n= Sibling Heading 2 =\n"))


(ert-deftest test-moin--demote-heading-with-subtree-error()
  "Checks `moin-command-meta-shift-right' for headings in error situations."
  ;; Cannot demote further
  (check-func-at-point-throws-error 'moin-command-meta-shift-right
   				    "===== Hallo =====" 8 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-shift-right
   				    "===== =====" 1 'user-error)
  ;; Not supported for active mark
  (check-func-at-point-throws-error 'moin-command-meta-shift-right
   				    "=== Hallo ===" 6 'user-error 3)
  ;; Cannot demote further due to child
  ;; TODO check why outline-mode asks for next heading - interactively it works...
  ;; (check-func-at-point-throws-error 'moin-command-meta-shift-right
  ;; 				    "Anytext before\n=== Heading 1 ===\nAny text behind\n==== H2.1 ====\nsubtext\n\n===== H3.1 =====\nsubtext\n===== H3.2 =====\nAny \nsub \ntext\n==== H2.2 ====\nHallo" 19 'user-error)
  )


(ert-deftest test-moin--promote-heading-with-subtree()
  "Checks `moin-command-meta-shift-left' for headings."
  ;; Headings without sub-headings
  (check-func-at-point 'moin-command-meta-shift-left "== Heading 2 ==" 1 1 "= Heading 2 =")
  (check-func-at-point 'moin-command-meta-shift-left "===  ===" 3 2 "==  ==")
  (check-func-at-point 'moin-command-meta-shift-left "==== Hallo ====" 8 7 "=== Hallo ===")
  (check-func-at-point 'moin-command-meta-shift-left "==== Heading 1 ====" 10 9 "=== Heading 1 ===")
  (check-func-at-point 'moin-command-meta-shift-left "Anytext before\n== Heading 2 ==\nAny text behind"
  		       23 22 "Anytext before\n= Heading 2 =\nAny text behind")
  (check-func-at-point 'moin-command-meta-shift-left "=== H ===" 10 8 "== H ==")
  ;; With multiple, single-level sub-headings
  (check-func-at-point 'moin-command-meta-shift-left
	     "Anytext before\n=== Heading 3 ===\nAny text behind\n==== H4.1 ====\nsubtext\n==== H4.2 ====\n"
		       18 17
	     "Anytext before\n== Heading 3 ==\nAny text behind\n=== H4.1 ===\nsubtext\n=== H4.2 ===\n")
  ;; With multiple, multi-level sub-headings
  (check-func-at-point 'moin-command-meta-shift-left
	     "Anytext before\n== Heading 1 ==\nAny text behind\n=== H2.1 ===\nsubtext\n\n==== H3.1 ====\nsubtext\n==== H3.2 ====\nAny \nsub \ntext\n=== H2.2 ===\nHallo"
		       29 28
	     "Anytext before\n= Heading 1 =\nAny text behind\n== H2.1 ==\nsubtext\n\n=== H3.1 ===\nsubtext\n=== H3.2 ===\nAny \nsub \ntext\n== H2.2 ==\nHallo")
  ;; With multiple, multi-level sub-headings, and sibling headings
  (check-func-at-point 'moin-command-meta-shift-left
	     "Anytext before\n== Heading 1 ==\nAny text behind\n=== H2.1 ===\nsubtext\n\n==== H3.1 ====\nsubtext\n==== H3.2 ====\nAny \nsub \ntext\n=== H2.2 ===\nHallo\n== Sibling Heading 1 ==\nAny text behind\n=== SH2.1 ===\nsubtext\n== Sibling Heading 2 ==\n"
		       29 28
	     "Anytext before\n= Heading 1 =\nAny text behind\n== H2.1 ==\nsubtext\n\n=== H3.1 ===\nsubtext\n=== H3.2 ===\nAny \nsub \ntext\n== H2.2 ==\nHallo\n== Sibling Heading 1 ==\nAny text behind\n=== SH2.1 ===\nsubtext\n== Sibling Heading 2 ==\n")
  (check-func-at-point 'moin-command-meta-shift-left
	     "Anytextfore\n== Heading 1 ==\nAny text behind\n=== H2.1 ===\nsubtext\n\n==== H3.1 ====\nsubtext\n==== H3.2 ====\nAny \nsub \ntext\n=== H2.2 ===\nHallo\n== Sibling Heading 1 ==\nAny text behind\n=== SH2.1 ===\nsubtext\n= Sibling Heading 2 =\n"
		       143 142
	     "Anytextfore\n== Heading 1 ==\nAny text behind\n=== H2.1 ===\nsubtext\n\n==== H3.1 ====\nsubtext\n==== H3.2 ====\nAny \nsub \ntext\n=== H2.2 ===\nHallo\n= Sibling Heading 1 =\nAny text behind\n== SH2.1 ==\nsubtext\n= Sibling Heading 2 =\n"))


(ert-deftest test-moin--promote-heading-with-subtree-error()
  "Checks `moin-command-meta-shift-left' for headings in error situations."
  ;; Cannot promote further
  (check-func-at-point-throws-error 'moin-command-meta-shift-left
   				    "= Hallo =" 8 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-shift-left
   				    "= =" 1 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-shift-left
    "Anytext before\n= Heading 1 =\nAny text behind\n==== H2.1 ====\nsubtext\n\n===== H3.1 =====\nsubtext\n===== H3.2 =====\nAny \nsub \ntext\n==== H2.2 ====\nHallo" 19 'user-error)
  ;; Not supported for active mark
  (check-func-at-point-throws-error 'moin-command-meta-shift-left
   				    "=== Hallo ===" 6 'user-error 3))


(ert-deftest test-moin--move-heading-up()
  "Checks `moin-command-meta-up' for headings."
  (test-moin--run-move-heading-up 'moin-command-meta-up))


(ert-deftest test-moin--move-heading-up-shift()
  "Checks `moin-command-meta-shift-up' for headings."
  (test-moin--run-move-heading-up 'moin-command-meta-shift-up))


(defun test-moin--run-move-heading-up(command)
  "Checks moving up of headings."
  ;; Headings without sub-headings
  (check-func-at-point command
		       "= Heading 1 =\n= Heading 2 =" 15 1 "= Heading 2 =\n= Heading 1 =\n")
  (check-func-at-point command
		       "= Heading 1 =\n= Heading 2 =\n" 25 11 "= Heading 2 =\n= Heading 1 =\n")
  ;; Headings with sub-headings
  (check-func-at-point command
		       "= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 2 =" 54 3
		       "= Heading 2 =\n= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n")
  (check-func-at-point command
		       "= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 2 =\n== Heading 2.1 ==\nAnyOther text\n=== Heading 3.1 ===\nAnyOther text\n== Heading 2.2 ==\nAnyOther text\n= Heading 3 =" 64 13
		       "= Heading 2 =\n== Heading 2.1 ==\nAnyOther text\n=== Heading 3.1 ===\nAnyOther text\n== Heading 2.2 ==\nAnyOther text\n= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 3 ="))


(ert-deftest test-moin--move-heading-up-error()
  "Checks `moin-command-meta-up' for headings in error situations."
  (test-moin--run-move-heading-up-error 'moin-command-meta-up))


(ert-deftest test-moin--move-heading-up-shift-error()
  "Checks `moin-command-meta-shift-up' for headings in error situations."
  (test-moin--run-move-heading-up-error 'moin-command-meta-shift-up))

(defun test-moin--run-move-heading-up-error(command)
  "Checks moving up of headings."
  (check-func-at-point-throws-error command
		       "= Heading 1 =\n= Heading 2 =" 1 'error)
  ;; On first sub-heading
  (check-func-at-point-throws-error command
		       "= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 2 =" 22 'error)
  (check-func-at-point-throws-error command
		       "= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 2 =\n== Heading 2.1 ==\nAnyOther text\n=== Heading 3.1 ===\nAnyOther text\n== Heading 2.2 ==\nAnyOther text\n= Heading 3 =" 103 'error))


(ert-deftest test-moin--move-heading-down()
  "Checks `moin-command-meta-down' for headings."
  (test-moin--run-move-heading-down 'moin-command-meta-down))


(ert-deftest test-moin--move-heading-down-shift()
  "Checks `moin-command-meta-shift-down' for headings."
  (test-moin--run-move-heading-down 'moin-command-meta-shift-down))


(defun test-moin--run-move-heading-down(command)
  "Checks moving down of headings."
  ;; Headings without sub-headings
  (check-func-at-point command
		       "= Heading 1 =\n= Heading 2 =" 1 15 "= Heading 2 =\n= Heading 1 =\n")
  (check-func-at-point command
		       "= Heading 1 =\n= Heading 2 =\n" 11 25 "= Heading 2 =\n= Heading 1 =\n")
  ;; Headings with sub-headings
  (check-func-at-point command
  		       "= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 2 =" 3 17
  		       "= Heading 2 =\n= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n")
  (check-func-at-point command
  		       "= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 2 =\n== Heading 2.1 ==\nAnyOther text\n=== Heading 3.1 ===\nAnyOther text\n== Heading 2.2 ==\nAnyOther text\n= Heading 3 =" 13 125
  		       "= Heading 2 =\n== Heading 2.1 ==\nAnyOther text\n=== Heading 3.1 ===\nAnyOther text\n== Heading 2.2 ==\nAnyOther text\n= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 3 ="))


(ert-deftest test-moin--move-heading-down-error()
  "Checks `moin-command-meta-down' for headings in error situations."
  (test-moin--run-move-heading-down-error 'moin-command-meta-down))


(ert-deftest test-moin--move-heading-down-shift-error()
  "Checks `moin-command-meta-shift-down' for headings in error situations."
  (test-moin--run-move-heading-down-error 'moin-command-meta-shift-down))

(defun test-moin--run-move-heading-down-error(command)
  "Checks moving down of headings."
  (check-func-at-point-throws-error command
				    "= Heading 1 =\n= Heading 2 =" 19 'error)
  ;; On last sub-heading
  (check-func-at-point-throws-error command
				    "= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 2 =" 22 'error)
  (check-func-at-point-throws-error command
				    "= Heading 1 =\ntext\n== Heading 1.1 ==\nAnyOther text\n= Heading 2 =\n== Heading 2.1 ==\nAnyOther text\n=== Heading 3.1 ===\nAnyOther text\n== Heading 2.2 ==\nAnyOther text\n= Heading 3 =" 103 'error))
  

;; TODO: Test `moin-command-tab' for headings, i.e. outline cycle 


;; ==================================================
;; Testing table functions

(ert-deftest test-moin-is-in-table-p-when-in-table ()
  "`moin-is-in-table-p' must return t when point is in a table."
  (test-moin--execute-on-file "auto_test_tables.txt" 'test-moin--check-is-in-table t))


(ert-deftest test-moin-is-in-table-p-when-not-in-table ()
  "`moin-is-in-table-p' must return nil when point is not in a table."
  (test-moin--execute-on-file "auto_test_notables.txt" 'test-moin--check-is-in-table nil))


(defun test-moin--check-is-in-table(expected)
  (while (not (eobp))
    (should (equal expected (moin-is-in-table-p)))
    (forward-char)))


(ert-deftest test-moin--table-create ()
  "Tests `moin--table-create' in positive cases"
  (test-moin--table-create-positive "" "" "1x1" 4 "||  ||\n\n")
  (test-moin--table-create-positive "" "" "3x1" 4 "||  ||  ||  ||\n\n")
  (test-moin--table-create-positive "Hallo" "Test" "4x3" 15 "\n\n||  ||  ||  ||  ||\n||  ||  ||  ||  ||\n||  ||  ||  ||  ||\n")
  (test-moin--table-create-positive "Hallo\n" "" "2x4" 10 "||  ||  ||\n||  ||  ||\n||  ||  ||\n||  ||  ||\n\n")
  (test-moin--table-create-positive "" "Test" "1x2" 4 "||  ||\n||  ||\n\n"))


(defun test-moin--table-create-positive (pre-text post-text size-string expected-point expected-table)
  (with-temp-buffer
    (moin-mode)
    (insert (concat pre-text post-text))
    (goto-char (+ (length pre-text) 1))
    (moin--table-create size-string)
    (message "test-moin--table-create-positive buffer string after funcall: %s" (buffer-string))
    (if (eq 0 (length pre-text))
	(should (equal (concat expected-table pre-text post-text) (buffer-string)))
      (should (equal (concat pre-text post-text expected-table) (buffer-string))))
    
    (should (equal expected-point (point)))))


(ert-deftest test-moin--table-create-error ()
  "Tests `moin--table-create' in negative cases"
  (check-func-at-point-throws-error 'moin--table-create "" 1 'user-error 0 "0x1")
  (check-func-at-point-throws-error 'moin--table-create "" 1 'user-error 0 "1x0")
  (check-func-at-point-throws-error 'moin--table-create "" 1 'user-error 0 "ANY TExt")
  (check-func-at-point-throws-error 'moin--table-create "" 1 'user-error 0 "x1")
  (check-func-at-point-throws-error 'moin--table-create "" 1 'user-error 0 "xx1")
  (check-func-at-point-throws-error 'moin--table-create "" 1 'user-error 0 "4x1x454")
  (check-func-at-point-throws-error 'moin--table-create "" 1 'user-error 0 "Sx1"))


(ert-deftest test-moin--table-determine-column-details()
  "Tests `moin--table-determine-column-details' for returning adequate values.
Expectations are given in the list form (current-column (start-point end-point content))"
  ;; Single row tables
  (test-moin--check-table-determine-column-details "||	 ||  ||" 4 (list 1 (list 3 5 "	 ") (list 7 9 "  ")))
  (test-moin--check-table-determine-column-details "||	 ||||" 3 (list 1 (list 3 5 "	 ") (list 7 7 "")))
  (test-moin--check-table-determine-column-details "||aaa||||" 8 (list 2 (list 3 6 "aaa") (list 8 8 "")))
  (test-moin--check-table-determine-column-details "|| my text || another text ||  ||" 32
		   (list 3 (list 3 12 " my text ") (list 14 28 " another text ") (list 30 32 "  ")))
  (test-moin--check-table-determine-column-details "||	 ||" 4 (list 1 (list 3 5 "	 ")))
  ;; Multi row tables
  (test-moin--check-table-determine-column-details "|| my text || a ||\n|| bbbbbbb || cccc ||" 15
						   (list 2 (list 3 12 " my text ") (list 14 17 " a ")))
  (test-moin--check-table-determine-column-details "|| a |||| b ||\n|| c || || ||\nAny Text behind" 27
				   (list 3 (list 18 21 " c ") (list 23 24 " ") (list 26 27 " ")))
  ;; Point on column borders
  (test-moin--check-table-determine-column-details "||	 ||  ||" 1 (list 1 (list 3 5 "	 ") (list 7 9 "  ")))
  (test-moin--check-table-determine-column-details "||	 ||  ||" 2 (list 1 (list 3 5 "	 ") (list 7 9 "  ")))
  (test-moin--check-table-determine-column-details "||	 ||  ||" 10 (list 2 (list 3 5 "	 ") (list 7 9 "  ")))
  (test-moin--check-table-determine-column-details "||	 ||  ||" 11 (list 2 (list 3 5 "	 ") (list 7 9 "  ")))
  (test-moin--check-table-determine-column-details "||	 ||  ||" 6 (list 1 (list 3 5 "	 ") (list 7 9 "  ")))
  (test-moin--check-table-determine-column-details "||	 ||  ||" 10 (list 2 (list 3 5 "	 ") (list 7 9 "  ")))
  (test-moin--check-table-determine-column-details "|| a |||| b ||\n|| c || || ||\nAny Text behind" 16 (list 1 (list 18 21 " c ") (list 23 24 " ") (list 26 27 " "))))


(defun test-moin--check-table-determine-column-details (text start-point expected-details)
  (with-temp-buffer
    (moin-mode)
    (insert text)
    (goto-char start-point)
    (setq column-details (moin--table-determine-column-details))
    (should (equal expected-details column-details))))


(ert-deftest test-moin--table-fix-field ()
  "Tests `moin--table-fix-field'"
  ;; Check that text is not changed
  (test-moin--check-fix-field 1 " Test " nil " Test ")
  ;; Check without blanks
  (test-moin--check-fix-field 1 "Test" nil " Test ")
  ;; Check with more or less blanks/tabs
  (test-moin--check-fix-field 1 " Test" nil " Test ")
  (test-moin--check-fix-field 1 "Test " nil " Test ")
  (test-moin--check-fix-field 1 "  Test " nil " Test ")
  (test-moin--check-fix-field 1 " 		 Test 	" nil " Test ")
  ;; Check with changed text
  (test-moin--check-fix-field 1 " Test " "NewText" " NewText ")
  (test-moin--check-fix-field 1 "Test	 " "NewText" " NewText ")
  ;; Check with any regexp special chars in the field text
  (test-moin--check-fix-field 1 " Te.*st " "NewText" " NewText ")
  (test-moin--check-fix-field 1 " Te.*st " nil " Te.*st " " thirst ||")
  (test-moin--check-fix-field 1 " T\\(.*\\)t " "New\\1Text" " New\\1Text ")
  ;; Check with currently empty field text
  (test-moin--check-fix-field 1 "" nil "  ")
  (test-moin--check-fix-field 1 "" "NewText" " NewText "))


(defun test-moin--check-fix-field (initial-point initial-field-text changed-field-text
						 expected-field-text &optional remaining-buffer-text)
  (with-temp-buffer
    (moin-mode)
    (setq initial-buffer-text
	  (concat moin-const-table-delimiter initial-field-text moin-const-table-delimiter
		  remaining-buffer-text))
    (setq expected-buffer-text
	  (concat moin-const-table-delimiter expected-field-text moin-const-table-delimiter
		  remaining-buffer-text))
    (insert initial-buffer-text)
    (goto-char initial-point)

    (moin--table-fix-field
     (list 3 (+ 3 (length initial-field-text)) initial-field-text) changed-field-text)
    
    (should (equal expected-buffer-text (buffer-string)))
    (should (equal (- (length expected-buffer-text) (length remaining-buffer-text) 1) (point)))))


(ert-deftest test-moin--table-next-field ()
  "Tests `moin-command-tab' for tables"
  ;; Just move to the next field of the same row, without any buffer changes
  (check-func-at-point 'moin-command-tab "||  ||  ||" 4 8)
  (check-func-at-point 'moin-command-tab "||  ||  ||" 3 8)
  (check-func-at-point 'moin-command-tab "|| my text || another text ||  ||" 6 15)
  (check-func-at-point 'moin-command-tab "|| my text || a ||\n|| bbbbbbb || cccc ||" 31 34)
  ;; Special case: Point before first field
  (check-func-at-point 'moin-command-tab "||  ||  ||" 2 4)
  (check-func-at-point 'moin-command-tab "||  ||  ||" 1 4)
  ;; Move point to next line if in last column, without any buffer changes
  (check-func-at-point 'moin-command-tab "|| my text || a ||\n|| bbbbbbb || cccc ||" 15 23)
  (check-func-at-point 'moin-command-tab "|| my text || a ||\n|| bbbbbbb || cccc ||" 16 23)
  (check-func-at-point 'moin-command-tab "|| my text || a ||\n|| bbbbbbb || cccc ||" 17 23)
  ;; Special case: Point after last field of a line
  (check-func-at-point 'moin-command-tab "|| my text || a ||\n|| bbbbbbb || cccc ||" 18 23)
  (check-func-at-point 'moin-command-tab "|| my text || a ||\n|| bbbbbbb || cccc ||" 19 23)
  ;; Table whitespace corrections
  (check-func-at-point 'moin-command-tab "|| || ||" 3 8 "||  ||  ||")
  (check-func-at-point 'moin-command-tab "||  ||||" 4 8 "||  ||  ||")
  (check-func-at-point 'moin-command-tab "||||||" 4 8 "||  ||  ||")
  (check-func-at-point 'moin-command-tab "||  ||||" 1 4 "||  ||||")
  (check-func-at-point 'moin-command-tab "|||| ||" 2 4 "||  || ||")
  (check-func-at-point 'moin-command-tab "|| my text||a ||\n||bbbbbbb|| cccc ||" 15 22
   					"|| my text|| a ||\n|| bbbbbbb || cccc ||")
  (check-func-at-point 'moin-command-tab "|| my text ||another text ||" 6 15 "|| my text || another text ||")
  (check-func-at-point 'moin-command-tab "|| my text || another text||" 6 15 "|| my text || another text ||")
  (check-func-at-point 'moin-command-tab "|| myt||a ||\n||bbbbbbb||cc  cc      ||\n||  	  	f || ||" 34 39
   					"|| myt||a ||\n||bbbbbbb|| cc  cc ||\n|| f || ||")
  ;; Create new line if issued in last field of table
  (check-func-at-point 'moin-command-tab "||  ||" 4 11 "||  ||\n||  ||\n")
  (check-func-at-point 'moin-command-tab "|| a |||| b ||\n|| c || || ||\nAny Text behind" 26 34 "|| a |||| b ||\n|| c || ||  ||\n||  ||  ||  ||\nAny Text behind"))


(ert-deftest test-moin--table-previous-field ()
  "Tests `moin-command-table-previous-field'"
  ;; Just move to the previous field of the same row, without any buffer changes
  (check-func-at-point 'moin-command-table-previous-field "||  ||  ||" 8 4)
  (check-func-at-point 'moin-command-table-previous-field "||  ||  ||" 7 4)
  (check-func-at-point 'moin-command-table-previous-field "|| my text || another text ||  ||" 15 4)
  (check-func-at-point 'moin-command-table-previous-field "|| my text || a ||\n|| bbbbbbb || cccc ||" 39 23)
  ;; Special case: Point after last field of row
  (check-func-at-point 'moin-command-table-previous-field "|| ||  ||" 10 7)
  (check-func-at-point 'moin-command-table-previous-field "|| ||  ||" 11 7)
  ;; Move point to previous line if in first column, without any buffer changes
  (check-func-at-point 'moin-command-table-previous-field "|| my text || a ||\n|| bbbbbbb || cccc ||" 22 15)
  (check-func-at-point 'moin-command-table-previous-field "|| my text || a ||\n|| bbbbbbb || cccc ||" 23 15)
  (check-func-at-point 'moin-command-table-previous-field "|| my text || a ||\n|| bbbbbbb || cccc ||" 27 15)
  ;; Special case: Point before first field of a line
  (check-func-at-point 'moin-command-table-previous-field "|| my text || a ||\n|| bbbbbbb || cccc ||" 21 15)
  (check-func-at-point 'moin-command-table-previous-field "|| my text || a ||\n|| bbbbbbb || cccc ||" 20 15)
  ;; Table whitespace corrections
  (check-func-at-point 'moin-command-table-previous-field "|| || ||" 7 4 "||  ||  ||")
  (check-func-at-point 'moin-command-table-previous-field "|||| ||" 7 6 "||||  ||")
  (check-func-at-point 'moin-command-table-previous-field "||||||" 5 4 "||  ||  ||")
  (check-func-at-point 'moin-command-table-previous-field "||   ||||" 10 9 "||   ||  ||")
  (check-func-at-point 'moin-command-table-previous-field "|||| ||" 7 6 "||||  ||")
  (check-func-at-point 'moin-command-table-previous-field "|| my text||a ||\n||bbbbbbb || cccc ||" 15 4
   	"|| my text || a ||\n||bbbbbbb || cccc ||")
  (check-func-at-point 'moin-command-table-previous-field "|| my text ||another text ||" 15 4
   	"|| my text || another text ||")
  (check-func-at-point 'moin-command-table-previous-field
  	"|| myt||   	  	f  ||\n||bbbbbbb  	||cc  cc      ||\n||a || ||" 33 10
   	"|| myt|| f ||\n|| bbbbbbb ||cc  cc      ||\n||a || ||"))


(ert-deftest test-moin--table-previous-field-error ()
  "Tests `moin-command-table-previous-field' in negative case"
  ;; Within first first field of a table
  (check-func-at-point-throws-error 'moin-command-table-previous-field "||  ||" 4 'user-error)
  ;; Not in a table
  (check-func-at-point-throws-error 'moin-command-table-previous-field "Any text" 4 'user-error))


(ert-deftest test-moin--table-insert-row ()
  "Tests `moin--table-insert-row'"
  ;; Inserting rows behind current row
  (check-func-at-point 'moin--table-insert-row "|| ||" 1 4 "||  ||\n|| ||" 0 (list nil))
  (check-func-at-point 'moin--table-insert-row "||||aaa ||" 9 4 "||  ||  ||\n||||aaa ||" 0 (list nil))
  (check-func-at-point 'moin--table-insert-row "||a||b||c||d||     e ||" 22 4
		       "||  ||  ||  ||  ||  ||\n||a||b||c||d||     e ||" 0 (list nil))
  ;; Inserting rows before current row (direct call)
  (check-func-at-point 'moin--table-insert-row "|| ||" 1 4 "||  ||\n|| ||" 0 t)
  (check-func-at-point 'moin--table-insert-row "||||aaa ||" 9 4 "||  ||  ||\n||||aaa ||" 0 t)
  (check-func-at-point 'moin--table-insert-row "||a||b||c||d||     e ||" 22 4
		       "||  ||  ||  ||  ||  ||\n||a||b||c||d||     e ||" 0 t)
  ;; Inserting rows before current row (command call)
  (check-func-at-point 'moin-command-meta-shift-down "|| ||" 1 4 "||  ||\n|| ||")
  (check-func-at-point 'moin-command-meta-shift-down "||||aaa ||" 9 4 "||  ||  ||\n||||aaa ||")
  (check-func-at-point 'moin-command-meta-shift-down "||a||b||c||d||     e ||" 22 4
		       "||  ||  ||  ||  ||  ||\n||a||b||c||d||     e ||"))


(ert-deftest test-moin--table-remove-row ()
  "Tests `moin-command-meta-shift-up' for tables"
  ;; Remove first row
  (check-func-at-point 'moin-command-meta-shift-up
      "|| ab ||\n|| xy ||" 5 5 "|| xy ||")
  ;; Remove sole row (no other content)
  (check-func-at-point 'moin-command-meta-shift-up
      "|| xy ||" 5 1 "")
  ;; Remove sole row (other content)
  (check-func-at-point 'moin-command-meta-shift-up
      "Ciao\n|| xy ||\nHallo" 14 11 "Ciao\nHallo")
  ;; Remove middle row, next row has at least (column-count) characters
  (check-func-at-point 'moin-command-meta-shift-up
      "|| ab || cde   || fg ||\n|||| hhhh   || ö ||\n||xyz|| test ||      ||\nAny text behind"
      38 38
      "|| ab || cde   || fg ||\n||xyz|| test ||      ||\nAny text behind")
  ;; Remove middle row, next row has less than (column-count) characters
  (check-func-at-point 'moin-command-meta-shift-up
      "|| ab || cde   || fg ||\n|||| hhhh   || ö ||\n||||||a||\nAny text behind"
      38 34
      "|| ab || cde   || fg ||\n||||||a||\nAny text behind")
  ;; Remove last row, previous row has at least (column-count) characters
  (check-func-at-point 'moin-command-meta-shift-up
      "|| ab || cde   || fg ||\n|||| hhhh   || ö ||\n||xyz|| test ||      ||\nAny text behind"
      52 32
      "|| ab || cde   || fg ||\n|||| hhhh   || ö ||\nAny text behind")
  ;; Remove last row, previous row has less than (column-count) characters
  (check-func-at-point 'moin-command-meta-shift-up
      "|| a || c || f ||\n|||| || ö ||\n||xyz|| test ||      ||\nAny text behind"
      54 31
      "|| a || c || f ||\n|||| || ö ||\nAny text behind"))


(ert-deftest test-moin--table-next-row ()
  "Tests `moin-command-return' in tables"
  ;; Moves to the next field and fixes previous and target field
  (check-func-at-point 'moin-command-return
      "|| ab ||\n|| xy ||" 5 13 "|| ab ||\n|| xy ||")
  (check-func-at-point 'moin-command-return
      "|| ||\n|| ||" 4 11 "||  ||\n||  ||")
  (check-func-at-point 'moin-command-return
      "|| abc||def ||\n|| || gef||\nAny Text" 12 23
      "|| abc|| def ||\n|| || gef ||\nAny Text")
  ;; Inserts a new table row
  (check-func-at-point 'moin-command-return
      "||      ab ||    ||\n||||||" 23 33
      "||      ab ||    ||\n||  ||||\n||  ||  ||\n")
  (check-func-at-point 'moin-command-return
      "||      ab ||    ||\nAny other text" 3 19
      "|| ab ||    ||\n||  ||  ||\nAny other text")
  (check-func-at-point 'moin-command-return
      "||      ab ||    ||\nAny other text" 15 26
      "||      ab ||  ||\n||  ||  ||\nAny other text")
  ;; Inserts a newline when issued at start or end of line
  (check-func-at-point 'moin-command-return
      "|| ab ||\n|| xy ||" 1 2 "\n|| ab ||\n|| xy ||")
  (check-func-at-point 'moin-command-return
      "|| ab ||\n|| xy ||" 9 10 "|| ab ||\n\n|| xy ||")
  (check-func-at-point 'moin-command-return
      "|| ab ||\n|| xy ||" 10 11 "|| ab ||\n\n|| xy ||")
  ;; Check with active region
  (check-func-at-point 'moin-command-return
      "|| abc||def ||\n|| || gef||\nAny Text" 10 23
      "|| abc|| def ||\n|| || gef ||\nAny Text" 2))


(ert-deftest test-moin-command-return-double ()
  "Tests `moin-command-return' outside of tables, in case
`moin-double-line-break-p' is t."
  (setq moin-double-line-break-p t)
  (check-func-at-point 'moin-command-return
      "" 1 3 "\n\n")
  (check-func-at-point 'moin-command-return
      "Hallo" 3 5 "Ha\n\nllo")
  (check-func-at-point 'moin-command-return
      "Hallo" 6 8 "Hallo\n\n"))


(ert-deftest test-moin-command-return-single ()
  "Tests `moin-command-return' outside of tables, in case
`moin-double-line-break-p' is nil."
  (setq moin-double-line-break-p nil)
  (check-func-at-point 'moin-command-return
      "" 1 2 "\n")
  (check-func-at-point 'moin-command-return
      "Hallo" 3 4 "Ha\nllo")
  (check-func-at-point 'moin-command-return
      "Hallo" 6 7 "Hallo\n"))


(ert-deftest test-moin--table-next-row-error ()
  "Tests `moin-command-return' in error situations"
  (check-func-at-point-throws-error
   'moin-command-return "|| abc||def ||\n|| ||" 10 'user-error))


(ert-deftest test-moin--table-copy-down ()
  "Tests `moin-command-table-copy-down'"
  ;; Moves to the next field, copies previous field content and fixes previous field
  (check-func-at-point 'moin-command-table-copy-down
      "|| ab ||\n||||" 5 13 "|| ab ||\n|| ab ||")
  (check-func-at-point 'moin-command-table-copy-down
      "|| ||\n|| ||" 4 11 "||  ||\n||  ||")
  (check-func-at-point 'moin-command-table-copy-down
      "|| abc||def ||\n|| ||    ||\nAny Text" 12 23
      "|| abc|| def ||\n|| || def ||\nAny Text")
  ;; Replaces any content in target column
  (check-func-at-point 'moin-command-table-copy-down
      "|| ab ||\n||xy||" 5 13 "|| ab ||\n|| ab ||")
  (check-func-at-point 'moin-command-table-copy-down
      "|| ab ||\n|| xy||" 5 13 "|| ab ||\n|| ab ||")
  (check-func-at-point 'moin-command-table-copy-down
      "|| ab ||\n||xy ||" 5 13 "|| ab ||\n|| ab ||")
  ;; Inserts a new table row
  (check-func-at-point 'moin-command-table-copy-down
      "||      ab ||    ||\n||||||" 23 33
      "||      ab ||    ||\n||  ||||\n||  ||  ||\n")
  (check-func-at-point 'moin-command-table-copy-down
      "||      ab ||    ||\nAny other text" 3 19
      "|| ab ||    ||\n|| ab ||  ||\nAny other text")
  (check-func-at-point 'moin-command-table-copy-down
      "||      ab || bap||\nAny other text" 15 29
      "||      ab || bap ||\n||  || bap ||\nAny other text")
  ;; Check with active region
  (check-func-at-point 'moin-command-table-copy-down
      "|| abc||def ||\n|| || gef||\nAny Text" 10 23
      "|| abc|| def ||\n|| || def ||\nAny Text" 2))


(ert-deftest test-moin--table-copy-down-error ()
   "Tests `moin-command-table-copy-down' in error situations"
  ;; Malformed next row
  (check-func-at-point-throws-error
   'moin-command-table-copy-down "|| abc||def ||\n|| ||" 10 'user-error)
  ;; Command not allowed at bol and eol
  (check-func-at-point-throws-error
   'moin-command-table-copy-down "|| abc||def ||" 1 'user-error)
  (check-func-at-point-throws-error
   'moin-command-table-copy-down "|| abc||def ||" 15 'user-error))


(ert-deftest test-moin--table-meta-return ()
  "Tests `moin-command-meta-return' in tables"
  ;; Moves to the next field, no split of previous field (end of field)
  ;; and fixes previous field
  (check-func-at-point 'moin-command-meta-return
      "|| ab ||\n||||" 6 13 "|| ab ||\n||  ||")
  (check-func-at-point 'moin-command-meta-return
      "|| ||\n|| ||" 4 11 "||  ||\n||  ||")
  ;; Splits content of current field down into (empty) target field
  (check-func-at-point 'moin-command-meta-return
      "||ab ||\n||||" 4 12 "|| a ||\n|| b ||")
  (check-func-at-point 'moin-command-meta-return
      "|| abc||def ||\n|| ||      ||\nAny Text" 9 20
      "|| abc||  ||\n|| || def ||\nAny Text")
  ;; Prepends any content in target column
  (check-func-at-point 'moin-command-meta-return
      "|| ab ||\n||xy||" 5 12 "|| a ||\n|| bxy ||")
  (check-func-at-point 'moin-command-meta-return
      "||ab ||\n|| xy    dfsdfsd ||" 3 11 "||  ||\n|| abxy    dfsdfsd ||")
  ;; Inserts a new table row
  (check-func-at-point 'moin-command-meta-return
      "||      ab ||    ||\n||||||" 23 33
      "||      ab ||    ||\n||  ||||\n||  ||  ||\n")
  (check-func-at-point 'moin-command-meta-return
      "||r      ab ||    ||\nAny other text" 4 18
      "|| r ||    ||\n|| ab ||  ||\nAny other text")
  (check-func-at-point 'moin-command-meta-return
      "||      ab || bap||\nAny other text" 17 28
      "||      ab || ba ||\n||  || p ||\nAny other text")
  ;; Check with active region
  (check-func-at-point 'moin-command-meta-return
      "|| abc||def ||\n|| || gef||\nAny Text" 10 22
      "|| abc|| de ||\n|| || fgef ||\nAny Text" 1)
  ;; Check within table delimiters (at beginning, middle and end of table)
  (check-func-at-point 'moin-command-meta-return
      "|| abc||def ||\n|| || gef||\nAny Text" 2 17
      "||  ||def ||\n|| abc || gef||\nAny Text")
  (check-func-at-point 'moin-command-meta-return
      "|| abc||def ||\n|| || gef||\nAny Text" 8 20
      "|| abc ||def ||\n||  || gef||\nAny Text")
  (check-func-at-point 'moin-command-meta-return
      "|| abc||def ||\n|| || gef||\nAny Text" 14 23
      "|| abc|| def ||\n|| || gef ||\nAny Text"))


(ert-deftest test-moin--meta-return-error ()
  "Tests `moin-command-meta-return' in error situations"
  ;; Malformed next row
  (check-func-at-point-throws-error
   'moin-command-meta-return "|| abc||def ||\n|| ||" 10 'user-error)
  ;; Command not allowed at bol and eol
  (check-func-at-point-throws-error
   'moin-command-meta-return "|| abc||def ||" 1 'user-error)
  (check-func-at-point-throws-error
   'moin-command-meta-return "|| abc||def ||" 15 'user-error))


(ert-deftest test-moin-move-row-up ()
  "Tests `moin-command-meta-up' for tables"
  
  (check-func-at-point 'moin-command-meta-up
      "|| ab ||\n||||" 10 1 "||||\n|| ab ||\n")
  (check-func-at-point 'moin-command-meta-up
      "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 35 11
      "|| ||      ||||\n|| abc||def || xyz   ||\n||tr|| rg || xy ||\nAny Text"))


(ert-deftest test-moin-move-row-up-error ()
  "Tests `moin-command-meta-up' for tables in error case"
  (check-func-at-point-throws-error
   'moin-command-meta-up "|| abc||def ||\n|| || ||" 10 'user-error)
  (check-func-at-point-throws-error
   'moin-command-meta-up "Any other text\n|| abc||def ||\nAny other text" 17 'user-error))


(ert-deftest test-moin-move-row-down ()
  "Tests `moin-command-meta-down' for tables"
  
  (check-func-at-point 'moin-command-meta-down
      "||||\n|| ab ||" 1 10 "|| ab ||\n||||\n")
  (check-func-at-point 'moin-command-meta-down
      "|| ||      ||||\n|| abc||def || xyz   ||\n||tr|| rg || xy ||\nAny Text" 11 35
      "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text"))


(ert-deftest test-moin-move-row-down-error ()
  "Tests `moin-command-meta-down' for tables in error case"
  (check-func-at-point-throws-error
   'moin-command-meta-down "|| abc||def ||\n|| || ||" 20 'user-error)
  (check-func-at-point-throws-error
   'moin-command-meta-down "Any other text\n|| abc||def ||\nAny other text" 17 'user-error))


(ert-deftest test-moin-move-column-left ()
  "Tests `moin-command-meta-left' for tables"
  
  (check-func-at-point 'moin-command-meta-left
		       "|| ab || cd ||" 10 3 "|| cd || ab ||")
  (check-func-at-point 'moin-command-meta-left
 		       "|| abc||def || xyz   ||\n|| ||      ||||" 36 27
 		       "||def || abc|| xyz   ||\n||      || ||||")
  (check-func-at-point 'moin-command-meta-left
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 9 3
  		       "||def || abc|| xyz   ||\n||      || ||||\n|| rg ||tr|| xy ||\nAny Text")
  (check-func-at-point 'moin-command-meta-left
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 36 27
  		       "||def || abc|| xyz   ||\n||      || ||||\n|| rg ||tr|| xy ||\nAny Text")
  (check-func-at-point 'moin-command-meta-left
 		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 58 47
 		       "|| abc|| xyz   ||def ||\n|| ||||      ||\n||tr|| xy || rg ||\nAny Text")
  (check-func-at-point 'moin-command-meta-left
		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 59 47
		       "|| abc|| xyz   ||def ||\n|| ||||      ||\n||tr|| xy || rg ||\nAny Text")
  ;; A longer table, 4 columns, 5 rows (row start points of table: 17, 42, 69, 86, 110)
  (setq multi-column-multi-row-table-string "Any text before\n|| ab||cd || ef   ||gh||\n||ij|| k ||     lm   ||o||\n||||p || q  ||||\n|| r||stuvw || x   ||||\n|| y||        || z   ||||\n")
  ;; Move second column left in first row
  (check-func-at-point 'moin-command-meta-left
       multi-column-multi-row-table-string 24 19
       "Any text before\n||cd || ab|| ef   ||gh||\n|| k ||ij||     lm   ||o||\n||p |||| q  ||||\n||stuvw || r|| x   ||||\n||        || y|| z   ||||\n")
  ;; Move third column left in third row
  (check-func-at-point 'moin-command-meta-left
       multi-column-multi-row-table-string 80 73
       "Any text before\n|| ab|| ef   ||cd ||gh||\n||ij||     lm   || k ||o||\n|||| q  ||p ||||\n|| r|| x   ||stuvw ||||\n|| y|| z   ||        ||||\n")
  ;; Move fourth column left in last row
  (check-func-at-point 'moin-command-meta-left
       multi-column-multi-row-table-string 134 126
"Any text before\n|| ab||cd ||gh|| ef   ||\n||ij|| k ||o||     lm   ||\n||||p |||| q  ||\n|| r||stuvw |||| x   ||\n|| y||        |||| z   ||\n"))


(ert-deftest test-moin-move-column-left-error ()
  "Tests `moin-command-meta-left' for tables in error cases"

  ;; Throws error when issued in first column
  (check-func-at-point-throws-error 'moin-command-meta-left
		       "|| ab || cd ||" 7 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-left
		       "|| ab || cd ||" 1 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-left
		       "|| ab || cd ||" 8 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-left
 		       "|| abc||def || xyz   ||\n|| ||      ||||" 26 'user-error)
  ;; Throws error when any other row is malformed (does not have enough columns)
  (check-func-at-point-throws-error 'moin-command-meta-left
 		       "|| abc||def || xyz   ||\n|| ||      ||" 16 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-left
 		       "|| abc||def ||\n|| ||      || gb ||" 31 'user-error))


(ert-deftest test-moin-move-column-right ()
  "Tests `moin-command-meta-right' for tables"
  
  (check-func-at-point 'moin-command-meta-right
		       "|| ab || cd ||" 3 9 "|| cd || ab ||")
  (check-func-at-point 'moin-command-meta-right
 		       "|| abc||def || xyz   ||\n|| ||      ||||" 27 35
 		       "||def || abc|| xyz   ||\n||      || ||||")
  (check-func-at-point 'moin-command-meta-right
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 3 9
  		       "||def || abc|| xyz   ||\n||      || ||||\n|| rg ||tr|| xy ||\nAny Text")
  (check-func-at-point 'moin-command-meta-right
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 27 35
  		       "||def || abc|| xyz   ||\n||      || ||||\n|| rg ||tr|| xy ||\nAny Text")
  (check-func-at-point 'moin-command-meta-right
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 47 53
  		       "|| abc|| xyz   ||def ||\n|| ||||      ||\n||tr|| xy || rg ||\nAny Text")
  (check-func-at-point 'moin-command-meta-right
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 51 53
  		       "|| abc|| xyz   ||def ||\n|| ||||      ||\n||tr|| xy || rg ||\nAny Text")
  ;; A longer table, 4 columns, 5 rows (row start points of table: 17, 42, 69, 86, 110)
  (setq multi-column-multi-row-table-string "Any text before\n|| ab||cd || ef   ||gh||\n||ij|| k ||     lm   ||o||\n||||p || q  ||||\n|| r||stuvw || x   ||||\n|| y||        || z   ||||\n")
  ;; Move first column right in first row
  (check-func-at-point 'moin-command-meta-right
       multi-column-multi-row-table-string 19 24
       "Any text before\n||cd || ab|| ef   ||gh||\n|| k ||ij||     lm   ||o||\n||p |||| q  ||||\n||stuvw || r|| x   ||||\n||        || y|| z   ||||\n")
  ;; Move second column right in third row
  (check-func-at-point 'moin-command-meta-right
       multi-column-multi-row-table-string 73 79
       "Any text before\n|| ab|| ef   ||cd ||gh||\n||ij||     lm   || k ||o||\n|||| q  ||p ||||\n|| r|| x   ||stuvw ||||\n|| y|| z   ||        ||||\n")
  ;; Move third column right in last row
  (check-func-at-point 'moin-command-meta-right
       multi-column-multi-row-table-string 130 128
       "Any text before\n|| ab||cd ||gh|| ef   ||\n||ij|| k ||o||     lm   ||\n||||p |||| q  ||\n|| r||stuvw |||| x   ||\n|| y||        |||| z   ||\n")
  )


(ert-deftest test-moin-move-column-right-error ()
  "Tests `moin-command-meta-right' for tables in error cases"

  ;; Throws error when issued in first column
  (check-func-at-point-throws-error 'moin-command-meta-right
		       "|| ab || cd ||" 9 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-right
		       "|| ab || cd ||" 11 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-right
		       "|| ab || cd ||" 15 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-right
 		       "|| abc||def || xyz   ||\n|| ||      ||||" 38 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-right
 		       "|| abc||def || xyz   ||\n|| ||      ||||" 39 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-right
 		       "|| abc||def || xyz   ||\n|| ||      ||||" 40 'user-error)

  ;; Throws error when any other row is malformed (does not have enough columns)
  (check-func-at-point-throws-error 'moin-command-meta-right
  		       "|| abc||def || xyz   ||\n|| ||" 13 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-right
         	       "|| abc||\n|| ||      || gb ||" 16 'user-error))


(ert-deftest test-moin-remove-column ()
  "Tests `moin-command-meta-shift-left' for tables"
  
  (check-func-at-point 'moin-command-meta-shift-left
		       "|| ab || cd ||" 10 3 "|| ab ||")
  (check-func-at-point 'moin-command-meta-shift-left
  		       "|| ab || cd ||" 8 3 "|| cd ||")
  (check-func-at-point 'moin-command-meta-shift-left
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 9 9
  		       "|| abc|| xyz   ||\n|| ||||\n||tr|| xy ||\nAny Text")
  (check-func-at-point 'moin-command-meta-shift-left
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 25 21
  		       "||def || xyz   ||\n||      ||||\n|| rg || xy ||\nAny Text")
  ;; Remove sole column of single-column table
  (check-func-at-point 'moin-command-meta-shift-left
  		       "|| abc||\n|| ||\n||tr||\nAny Text" 13 2
  		       "\n\n\nAny Text")
  ;; A longer table, 4 columns, 5 rows (row start points of table: 17, 42, 69, 86, 110)
  (setq multi-column-multi-row-table-string
  	"Any text before\n|| ab||cd || ef   ||gh||\n||ij|| k ||     lm   ||o||\n||||p || q  ||||\n|| r||stuvw || x   ||||\n|| y||        || z   ||||\n")
  ;; Remove second column in first row
  (check-func-at-point 'moin-command-meta-shift-left multi-column-multi-row-table-string 25 24
        "Any text before\n|| ab|| ef   ||gh||\n||ij||     lm   ||o||\n|||| q  ||||\n|| r|| x   ||||\n|| y|| z   ||||\n")
  ;; Remove third column in third row
  (check-func-at-point 'moin-command-meta-shift-left multi-column-multi-row-table-string 80 57
        "Any text before\n|| ab||cd ||gh||\n||ij|| k ||o||\n||||p ||||\n|| r||stuvw ||||\n|| y||        ||||\n")
  ;; Remove fourth column in last row
  (check-func-at-point 'moin-command-meta-shift-left multi-column-multi-row-table-string 134 115
  		       "Any text before\n|| ab||cd || ef   ||\n||ij|| k ||     lm   ||\n||||p || q  ||\n|| r||stuvw || x   ||\n|| y||        || z   ||\n"))


(ert-deftest test-moin-remove-column-error ()
  "Tests `moin-command-meta-shift-left' for tables in error cases"
  ;; Throws error when any other row is malformed (does not have enough columns)
  (check-func-at-point-throws-error 'moin-command-meta-shift-left
  		       "|| abc||def || xyz   ||\n|| ||" 13 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-shift-left
         	       "|| abc||\n|| ||      || gb ||" 16 'user-error))


(ert-deftest test-moin-insert-column ()
  "Tests `moin-command-meta-shift-right' for tables"
  
  (check-func-at-point 'moin-command-meta-shift-right
		       "|| ab || cd ||" 10 10 "|| ab ||  || cd ||")
  (check-func-at-point 'moin-command-meta-shift-right
  		       "|| ab || cd ||" 8 4 "||  || ab || cd ||")
  (check-func-at-point 'moin-command-meta-shift-right
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 9 10
  		       "|| abc||  ||def || xyz   ||\n|| ||  ||      ||||\n||tr||  || rg || xy ||\nAny Text")
  (check-func-at-point 'moin-command-meta-shift-right
  		       "|| abc||def || xyz   ||\n|| ||      ||||\n||tr|| rg || xy ||\nAny Text" 25 32
  		       "||  || abc||def || xyz   ||\n||  || ||      ||||\n||  ||tr|| rg || xy ||\nAny Text")
  ;; Insert column before sole column of single-column table
  (check-func-at-point 'moin-command-meta-shift-right
  		       "|| abc||\n|| ||\n||tr||\nAny Text" 13 17
  		       "||  || abc||\n||  || ||\n||  ||tr||\nAny Text")
  ;; A longer table, 4 columns, 5 rows (row start points of table: 17, 42, 69, 86, 110)
  (setq multi-column-multi-row-table-string
  	"Any text before\n|| ab||cd || ef   ||gh||\n||ij|| k ||     lm   ||o||\n||||p || q  ||||\n|| r||stuvw || x   ||||\n|| y||        || z   ||||\n")
  ;; Insert new column, triggered in second column in first row
  (check-func-at-point 'moin-command-meta-shift-right multi-column-multi-row-table-string 25 25
        "Any text before\n|| ab||  ||cd || ef   ||gh||\n||ij||  || k ||     lm   ||o||\n||||  ||p || q  ||||\n|| r||  ||stuvw || x   ||||\n|| y||  ||        || z   ||||\n")
  ;; Insert new column, triggered in third column in third row
  (check-func-at-point 'moin-command-meta-shift-right multi-column-multi-row-table-string 80 86
        "Any text before\n|| ab||cd ||  || ef   ||gh||\n||ij|| k ||  ||     lm   ||o||\n||||p ||  || q  ||||\n|| r||stuvw ||  || x   ||||\n|| y||        ||  || z   ||||\n")
  ;; Insert new column, triggered in fourth column in last row
  (check-func-at-point 'moin-command-meta-shift-right multi-column-multi-row-table-string 134 150
       "Any text before\n|| ab||cd || ef   ||  ||gh||\n||ij|| k ||     lm   ||  ||o||\n||||p || q  ||  ||||\n|| r||stuvw || x   ||  ||||\n|| y||        || z   ||  ||||\n"))


(ert-deftest test-moin-insert-column-error ()
  "Tests `moin-command-meta-shift-right' for tables in error cases"
  ;; Throws error when any other row is malformed (does not have enough columns)
  (check-func-at-point-throws-error 'moin-command-meta-shift-right
  		       "|| abc||def || xyz   ||\n|| ||" 13 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-shift-right
         	       "|| abc||\n|| ||      || gb ||" 16 'user-error))
  


;; ==================================================
;; Testing list functions


(ert-deftest test-moin-is-in-list-p-when-in-list ()
  "`moin-is-in-list-p' must return t when point is in a list."
  (test-moin--execute-on-file "auto_test_lists.txt" 'test-moin--check-is-in-list t))


(ert-deftest test-moin-is-in-list-p-when-not-in-list ()
  "`moin-is-in-list-p' must return nil when point is not in a list."
  (test-moin--execute-on-file "auto_test_nolists.txt" 'test-moin--check-is-in-list nil))


(defun test-moin--check-is-in-list(expected)
  (while (not (eobp))
    (should (equal expected (moin-is-in-list-p)))
    (forward-char)))


(ert-deftest test-moin--list-get-item-info ()
  "Tests `moin--list-get-item-info'"
  (check-read-only-func-at-point 'moin--list-get-item-info
    				 " * My item \n * Yours" 15 (list 13 21 16 1 " " "*" " "))
  (check-read-only-func-at-point 'moin--list-get-item-info
    				 " * My item \n * Yours\n" 15 (list 13 21 16 1 " " "*" " "))

  (setq test-buffer-text " * asdas\n . asdsa\n .\n   * next level\n   1.ha\n   A.\n df\n sds\n   \n	\n	\n\n   \n\n\n\n   q.\n   i.\n\n   I.\n                  .\n		  1.\n\n\n 22.\n \n o.\n  \n\n looney item\n")
  
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 1 (list 1 9 4 1 " " "*" " "))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 16 (list 10 18 13 1 " " "." " "))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 20 (list 19 21 21 1 " " "." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 37 (list 22 37 27 3 "   " "*" " "))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 39 (list 38 45 43 3 "   " "1." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 58 (list 46 76 51 3 "   " "A." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 67 (list 46 76 51 3 "   " "A." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 73 (list 46 76 51 3 "   " "A." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 76 (list 46 76 51 3 "   " "A." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 107 (list 96 115 115 18 "                  " "." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 124 (list 116 124 122 4 "		  " "1." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 127 (list 125 131 129 1 " " "22." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 132 (list 132 152 135 1 " " "o." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 133 (list 132 152 135 1 " " "o." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 136 (list 132 152 135 1 " " "o." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 138 (list 132 152 135 1 " " "o." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 139 (list 132 152 135 1 " " "o." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 145 (list 132 152 135 1 " " "o." ""))
  (check-read-only-func-at-point 'moin--list-get-item-info test-buffer-text
  				 152 (list 132 152 135 1 " " "o." "")))
 

(ert-deftest test-moin--get-list-item-info-error ()
  "Tests the behaviour of `moin--list-get-item-info' if not in a list."
  (check-read-only-func-at-point 'moin--list-get-item-info "arbitrary other test text" 10 nil)
  (check-read-only-func-at-point 'moin--list-get-item-info "A. sadasdasd" 1 nil)
  (check-read-only-func-at-point 'moin--list-get-item-info "*" 2 nil))


(ert-deftest test-moin--list-insert-item-same-level ()
  "Tests `moin-command-meta-return' in lists"
  
  ;; Point behind the text of the item - Is expected to create a new item after the current one
  ;; with same bullet and indentation before and after bullet, no text after that.
  (check-func-at-point 'moin-command-meta-return " * Text" 8 12 " * Text\n * ")
  (check-func-at-point 'moin-command-meta-return " *t" 4 7 " *t\n *")
  (check-func-at-point 'moin-command-meta-return " A.   a" 8 15 " A.   a\n A.   ")
  (check-func-at-point 'moin-command-meta-return " i.My text" 11 15 " i.My text\n i.")
  (check-func-at-point 'moin-command-meta-return " .another text" 15 18 " .another text\n .")
  (check-func-at-point 'moin-command-meta-return " o.  	\n  \n\n looney item" 24 31 " o.  	\n  \n\n looney item\n o.  	")
  ;; Point before the text of the item - Is expected to create a new item before the current one
  ;; with same bullet and indentation before and after bullet, no text after that on the same line.
  (check-func-at-point 'moin-command-meta-return " * Text" 1 4 " * \n * Text")
  (check-func-at-point 'moin-command-meta-return " *" 3 3 " *\n *")
  (check-func-at-point 'moin-command-meta-return " A.   a" 7 7 " A.   \n A.   a")
  (check-func-at-point 'moin-command-meta-return " i.My text" 3 4 " i.\n i.My text")
  (check-func-at-point 'moin-command-meta-return " .another text" 1 3 " .\n .another text")
  (check-func-at-point 'moin-command-meta-return " o.	\n  \n\n looney item" 4 5 " o.	\n o.	\n  \n\n looney item")
  ;; Point within the text of the item - Is expected to create a new item after the current one
  ;; with same bullet and indentation before and after bullet, with the text of the current item after point
  ;; as text of the new item.
  (check-func-at-point 'moin-command-meta-return " * Text" 6 10 " * Te\n * xt")
  (check-func-at-point 'moin-command-meta-return " i.My text" 7 11 " i.My \n i.text")
  (check-func-at-point 'moin-command-meta-return " .another text" 6 9 " .ano\n .ther text")
  (check-func-at-point 'moin-command-meta-return " o.	\n  \n\n looney item" 6 10 " o.	\n o.	  \n\n looney item")
  (check-func-at-point 'moin-command-meta-return " o.	\n  \n\n looney item" 9 13 " o.	\n  \n o.	\n looney item")
  ;; Insert item at the end of a list after whitespace behind the last item
  (check-func-at-point 'moin-command-meta-return " * Text\n * Last item\n" 22 25 " * Text\n * Last item\n * ")
  (check-func-at-point 'moin-command-meta-return " * Text\n * Last item\n  \n	\n" 25 28 " * Text\n * Last item\n  \n * 	\n")
  (check-func-at-point 'moin-command-meta-return " * Text\n * Last item\n\n\n\n" 24 27 " * Text\n * Last item\n\n\n * \n"))


(ert-deftest test-moin--list-insert-item-same-level-error ()
  "Tests the behaviour of `moin--list-insert-item-same-level' if not in a list."
  (check-func-at-point-throws-error 'moin--list-insert-item-same-level "arbitrary other test text" 10 'user-error)
  (check-func-at-point-throws-error 'moin--list-insert-item-same-level "A. sadasdasd" 1 'user-error)
  (check-func-at-point-throws-error 'moin--list-insert-item-same-level "*" 2 'user-error))


(ert-deftest test-moin-command-create-bullet-list--point-after-text()
  "Tests `moin-command-create-bullet-list' with point after text. Expectation: Creates a new list at the next line."
  (setq text-before "Any text in line")
  (test-moin--check-create-list 'moin-command-create-bullet-list text-before (+ 1 (length text-before)) moin-const-bullet-list))


(ert-deftest test-moin-command-create-bullet-list--point-within-text()
  "Tests `moin-command-create-bullet-list' with point at within text. Expectation: Creates a new list after the current line, with the text after point as first item's text."
  (test-moin--check-create-list 'moin-command-create-bullet-list "Any text in line" 5 moin-const-bullet-list))


(ert-deftest test-moin-command-create-bullet-list--point-at-beginning-of-line()
  "Tests `moin-command-create-bullet-list' with point at beginning of line. Expectation: Creates a new list on the current line, with the text after point as first item's text."
  (test-moin--check-create-list 'moin-command-create-bullet-list "Any text in line" 1 moin-const-bullet-list))


(ert-deftest test-moin-command-create-bullet-list--point-in-empty-line()
  "Tests `moin-command-create-bullet-list' with point on an empty line. Expectation: Creates a new list within the current line."
  (test-moin--check-create-list 'moin-command-create-bullet-list "" 1 moin-const-bullet-list))


(ert-deftest test-moin-command-create-bullet-list--point-in-existing-list()
  "Tests `moin-command-create-bullet-list' with point in an existing list. Expectation: Creates a new list item within the current list on top level."
  (test-moin--check-create-list 'moin-command-create-bullet-list " * " 4 moin-const-bullet-list)
  (test-moin--check-create-list 'moin-command-create-bullet-list "    A. Item with more indent" 9 moin-const-bullet-list))

(ert-deftest test-moin-command-create-bullet-list--point-after-text()
  "Tests `moin-command-create-bullet-list' with point after text. Expectation: Creates a new list at the next line."
  (setq text-before "Any text in line")
  (test-moin--check-create-list 'moin-command-create-bullet-list text-before (+ 1 (length text-before)) moin-const-bullet-list))


(ert-deftest test-moin-command-create-numbered-list--point-within-text()
  "Tests `moin-command-create-numbered-list' with point at within text. Expectation: Creates a new list after the current line, with the text after point as first item's text."
  (test-moin--check-create-list 'moin-command-create-numbered-list "Any text in line" 5 moin-const-numbered-list))


(ert-deftest test-moin-command-create-numbered-list--point-at-beginning-of-line()
  "Tests `moin-command-create-numbered-list' with point at beginning of line. Expectation: Creates a new list on the current line, with the text after point as first item's text."
  (test-moin--check-create-list 'moin-command-create-numbered-list "Any text in line" 1 moin-const-numbered-list))


(ert-deftest test-moin-command-create-numbered-list--point-in-empty-line()
  "Tests `moin-command-create-numbered-list' with point on an empty line. Expectation: Creates a new list within the current line."
  (test-moin--check-create-list 'moin-command-create-numbered-list "" 1 moin-const-numbered-list))


(ert-deftest test-moin-command-create-numbered-list--point-in-existing-list()
  "Tests `moin-command-create-numbered-list' with point in an existing list. Expectation: Creates a new list item within the current list on top level."
  (test-moin--check-create-list 'moin-command-create-numbered-list " * " 4 moin-const-numbered-list)
  (test-moin--check-create-list 'moin-command-create-numbered-list "    A. Item with more indent" 9 moin-const-numbered-list))


(defun test-moin--check-create-list(command text-before split-at-point expected-bullet-text)
  (with-temp-buffer
    (insert text-before)
    (goto-char split-at-point)
    (funcall command)
    (message "Buffer string after test method call:\n%s" (buffer-string))
    
    (if (eq split-at-point (+ (length text-before) 1))
	(should (equal t (eolp))))

    (if (> split-at-point 1)
	(previous-line))
    
    (beginning-of-line)
    ;; Check text before new list (if any)
    (should (equal (substring text-before 0 (- split-at-point 1)) (buffer-substring-no-properties (point) split-at-point)))
    
    (if (> split-at-point 1)
	(next-line))
    
    ;; Check that bullet is correctly inserted
    (should (equal expected-bullet-text (buffer-substring-no-properties (point) (+ (point) (length expected-bullet-text)))))
    (forward-char (length expected-bullet-text))
    
    ;; Check text of first list item
    (should (equal (substring text-before (- split-at-point 1)) (buffer-substring-no-properties (point) (+ 1 (point) (- (length text-before) split-at-point)))))))


(ert-deftest test--moin-list-move-subtree-up ()
  "Tests `moin-command-meta-up' for lists"
  (test--check-moin-list-move-subtree-up 'moin-command-meta-up))

(ert-deftest test--moin-list-move-subtree-up-shift ()
  "Tests `moin-command-meta-shift-up' for lists"
  (test--check-moin-list-move-subtree-up 'moin-command-meta-shift-up))


(defun test--check-moin-list-move-subtree-up (func)
  "Tests `moin-command-meta-up' for lists"

  ;; Items without subitems, without multiline items
  (check-func-at-point func
  		       " * My item \n * Yours" 15 3 " * Yours\n * My item \n")
  (check-func-at-point func
  		       " * My item \n * Yours\n" 15 3 " * Yours\n * My item \n")
  (check-func-at-point func
  		       " * My item \n * Yours\n * third" 15 3 " * Yours\n * My item \n * third")
  (check-func-at-point func
  		       "Text before\n * My item \n * Yours\nText behind" 32 20
  		       "Text before\n * Yours\n * My item \nText behind")
  (check-func-at-point func
  		       " * First item\n * My item \n * Yours\nText behind" 29 17
  		       " * First item\n * Yours\n * My item \nText behind")
  ;; Items without subitems, with multiline items
  (check-func-at-point func
  		       " * My item\n \n * Yours" 15 2 " * Yours\n * My item\n \n")
  (check-func-at-point func
   		       " * My item \n * Yours\n   \n \n \n" 15 3 " * Yours\n   \n \n \n * My item \n")
  (check-func-at-point func
  		       "TextBefore\n * My item\n \n * Yours\n\t\n \n \n * third\n \n \n \nTextBehind" 29 16
  		       "TextBefore\n * Yours\n\t\n \n \n * My item\n \n * third\n \n \n \nTextBehind")
  ;; Previous item has subitems
  (check-func-at-point func
  		       " * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n * Yours" 66 5
  		       " * Yours\n * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n")
  ;; Current item has subitems
  (check-func-at-point func
   " * My item\n * Yours \n  * Subitem 1\n   * Subitem 1.1\n   * Subitem 1.2\n    * Subitem 1.2.1\n  * Subitem 2" 18 7
   " * Yours \n  * Subitem 1\n   * Subitem 1.1\n   * Subitem 1.2\n    * Subitem 1.2.1\n  * Subitem 2\n * My item\n")
  ;; Most complex mixture of all cases
  (check-func-at-point func
  		       "Any Text before\n * Very first\n  * Sub1\n  * Sub2\n * My item\n  * My Sub 1\n  * My Sub 2\n  * My Sub 3\n   * My Sub 3.1\n    * My Sub 3.1.1\n     * My Sub 3.1.1.1\n \n \n \n * Yours\n  * Subitem 1\n   * Subitem 1.1\n   * Subitem 1.2\n    * Subitem 1.2.1\n \n \n      \n  * Subitem 2\n \n   \n * Third item\n   * Text\n\n Any Text behind" 165 52
  		       "Any Text before\n * Very first\n  * Sub1\n  * Sub2\n * Yours\n  * Subitem 1\n   * Subitem 1.1\n   * Subitem 1.2\n    * Subitem 1.2.1\n \n \n      \n  * Subitem 2\n \n   \n * My item\n  * My Sub 1\n  * My Sub 2\n  * My Sub 3\n   * My Sub 3.1\n    * My Sub 3.1.1\n     * My Sub 3.1.1.1\n \n \n \n * Third item\n   * Text\n\n Any Text behind")
  ;; Moving an item at end of list with an empty line behind
  (check-func-at-point func
  		       " * My item \n * Yours\n" 15 3 " * Yours\n * My item \n")
  (check-func-at-point func
  		       " * My item \n * Yours\n\n" 15 3 " * Yours\n * My item \n\n")
  (check-func-at-point func
  		       " * My item \n * Yours\n\n\n\n" 15 3 " * Yours\n * My item \n\n\n\n")
  (check-func-at-point func
  		       " * My item \n * Yours\n\n  \n\n" 15 3 " * Yours\n\n  \n * My item \n\n")
  (check-func-at-point func " * a\n * text\n\n= Test =\n" 9 4 " * text\n * a\n\n= Test =\n"))


(ert-deftest test--moin-list-move-subtree-up-error ()
  "Tests `moin-command-meta-up' for lists in negative cases"
  (test--check-moin-list-move-subtree-up-error 'moin-command-meta-up))


(ert-deftest test--moin-list-move-subtree-up-shift-error ()
  "Tests `moin-command-meta-shift-up' for lists in negative cases"
  (test--check-moin-list-move-subtree-up-error 'moin-command-meta-shift-up))


(defun test--check-moin-list-move-subtree-up-error (func)
  "Tests `moin-command-meta-up' for lists in negative cases"
  (check-func-at-point-throws-error func
  		       " * My item \n * Yours" 5 'user-error)
  (check-func-at-point-throws-error func
  		       "Text before\n * My item \n * Yours\nText behind" 24 'user-error)
  (check-func-at-point-throws-error func
   " * My item\n * Yours \n  * Subit 1\n   * Subit 1.1\n   * Subit 1.2\n    * Subitem 1.2.1" 24  'user-error)
  (check-func-at-point-throws-error func
   " * My item\n * Yours \n  * Subit 1\n   * Subit 1.1\n   * Subit 1.2\n    * Subitem 1.2.1" 68  'user-error))


(ert-deftest test--moin-list-move-subtree-down ()
  "Tests `moin-command-meta-down' for lists"
  (test--check-moin-list-move-subtree-down 'moin-command-meta-down))

(ert-deftest test--moin-list-move-subtree-down-shift ()
  "Tests `moin-command-meta-shift-down' for lists"
  (test--check-moin-list-move-subtree-down 'moin-command-meta-shift-down))


(defun test--check-moin-list-move-subtree-down (func)
  "Tests `moin-command-meta-down' for lists"

  ;; Items without subitems, without multiline items
  (check-func-at-point func
  		       " * My item \n * Yours" 5 14 " * Yours\n * My item \n")
  (check-func-at-point func
  		       " * My item \n * Yours\n" 5 14 " * Yours\n * My item \n")
  (check-func-at-point func
  		       " * My item \n * Yours\n * third" 5 14 " * Yours\n * My item \n * third")
  (check-func-at-point func
  		       "Text before\n * My item \n * Yours\nText behind" 20 29
  		       "Text before\n * Yours\n * My item \nText behind")
  (check-func-at-point func
  		       " * First item\n * My item \n * Yours\nText behind" 17 26
  		       " * First item\n * Yours\n * My item \nText behind")
  ;; Items without subitems, with multiline items
  (check-func-at-point func
  		       " * My item\n \n * Yours" 2 11 " * Yours\n * My item\n \n")
  (check-func-at-point func
   		       " * My item \n * Yours\n   \n \n \n" 3 20 " * Yours\n   \n \n \n * My item \n")
  (check-func-at-point func
  		       "TextBefore\n * My item\n \n * Yours\n\t\n \n \n * third\n \n \n \nTextBehind" 16 31
  		       "TextBefore\n * Yours\n\t\n \n \n * My item\n \n * third\n \n \n \nTextBehind")
  ;; Previous item has subitems
  (check-func-at-point func
  		       " * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n * Yours" 5 14
  		       " * Yours\n * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n")
  ;; Current item has subitems
  (check-func-at-point func
   " * My item\n * Yours \n  * Subitem 1\n   * Subitem 1.1\n   * Subitem 1.2\n    * Subitem 1.2.1\n  * Subitem 2" 7 99
   " * Yours \n  * Subitem 1\n   * Subitem 1.1\n   * Subitem 1.2\n    * Subitem 1.2.1\n  * Subitem 2\n * My item\n")
  ;; Most complex mixture of all cases
  (check-func-at-point func
  		       "Any Text before\n * Very first\n  * Sub1\n  * Sub2\n * My item\n  * My Sub 1\n  * My Sub 2\n  * My Sub 3\n   * My Sub 3.1\n    * My Sub 3.1.1\n     * My Sub 3.1.1.1\n \n \n \n * Yours\n  * Subitem 1\n   * Subitem 1.1\n   * Subitem 1.2\n    * Subitem 1.2.1\n \n \n      \n  * Subitem 2\n \n   \n * Third item\n   * Text\n\n Any Text behind" 52 160
  		       "Any Text before\n * Very first\n  * Sub1\n  * Sub2\n * Yours\n  * Subitem 1\n   * Subitem 1.1\n   * Subitem 1.2\n    * Subitem 1.2.1\n \n \n      \n  * Subitem 2\n \n   \n * My item\n  * My Sub 1\n  * My Sub 2\n  * My Sub 3\n   * My Sub 3.1\n    * My Sub 3.1.1\n     * My Sub 3.1.1.1\n \n \n \n * Third item\n   * Text\n\n Any Text behind")
  ;; Moving an item to be the last item in the list, and the current
  ;; last item has an empty line behind
  (check-func-at-point func
  		       " * My item \n * Yours\n\n" 8 17 " * Yours\n * My item \n\n")
  (check-func-at-point func " * a\n * text\n\n= Test =\n" 4 12 " * text\n * a\n\n= Test =\n"))


(ert-deftest test--moin-list-move-subtree-down-error ()
  "Tests `moin-command-meta-down' for lists in negative cases"
  (test--check-moin-list-move-subtree-down-error 'moin-command-meta-down))


(ert-deftest test--moin-list-move-subtree-down-shift-error ()
  "Tests `moin-command-meta-shift-down' for lists in negative cases"
  (test--check-moin-list-move-subtree-down-error 'moin-command-meta-shift-down))


(defun test--check-moin-list-move-subtree-down-error (func)
  "Tests `moin-command-meta-down' for lists in negative cases"
  (check-func-at-point-throws-error func
  		       " * My item \n * Yours" 15 'user-error)
  (check-func-at-point-throws-error func
  		       "Text before\n * My item \n * Yours\nText behind" 30 'user-error)
  (check-func-at-point-throws-error func
   " * My item\n * Yours \n  * Subit 1\n   * Subit 1.1\n   * Subit 1.2\n    * Subitem 1.2.1" 30  'user-error)
  (check-func-at-point-throws-error func
  				    " * My item\n * Yours \n  * Subit 1\n   * Subit 1.1\n   * Subit 1.2\n    * Subitem 1.2.1" 68  'user-error))


(defun test--moin-list-indentation-no-subtree(command)
  "Checks list indentation with or without subtree on items that do not
have a subtree, the behavior for both commands must be the same."
    ;; Items without subitems, without multiline items
  (check-func-at-point command
  		       " * My item \n * Yours" 17 18 " * My item \n  * Yours")
  (check-func-at-point command
  		       " * My item \n * Yours\n" 17 18 " * My item \n  * Yours\n")
  (check-func-at-point command
  		       " * My item \n * Yours\n * third" 17 18 " * My item \n  * Yours\n * third")
  (check-func-at-point command
  		       "Text before\n * My item \n * Yours\nText behind" 26 27
  		       "Text before\n * My item \n  * Yours\nText behind")
  ;; Indent multiline items
  (check-func-at-point command
       " * My item\n * Yours\n   \n \n \n * third" 19 20 " * My item\n  * Yours\n    \n  \n  \n * third")
  (check-func-at-point command
  " * My item\n * Yours\n   \n \n \n\t\n   \n * third" 19 20 " * My item\n  * Yours\n    \n  \n  \n \t\n    \n * third")
  (check-func-at-point command
		       "TextBefore\n * My item\n * Yours\n   \n \n \n\t\n   \nText behind" 30 31 "TextBefore\n * My item\n  * Yours\n    \n  \n  \n \t\n    \nText behind")
    ;; Indent items after previous higher level items
  (check-func-at-point 'moin-command-meta-shift-right
  		       " * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n * Yours" 70 71
  		       " * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n  * Yours"))


(defun test--moin-list-indentation-error (command)
  "Tests list indendation for any command in negative cases"
  
  (check-func-at-point-throws-error command
  		       " * My item" 9 'user-error)
  (check-func-at-point-throws-error command
  		       " * My item\n  * My Subitem" 16 'user-error))


(ert-deftest test--moin-list-indent-item ()
  "Tests `moin-command-meta-right' for lists"

  (test--moin-list-indentation-no-subtree 'moin-command-meta-right)

  ;; Parent item with subitems is indented - the child remains unchanged
  (check-func-at-point 'moin-command-meta-right
  		       " * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n * Yours" 35 36
  		       " * My item \n   * Subitem 1\n    * Subitem 2\n     * Subitem 2.1\n * Yours"))


(ert-deftest test--moin-list-indent-item-error ()
  "Tests `moin-command-meta-right' for lists in negative cases"

  (test--moin-list-indentation-error 'moin-command-meta-right))
  

(ert-deftest test--moin-list-indent-subtree ()
  "Tests `moin-command-meta-shift-right' for lists"

  (test--moin-list-indentation-no-subtree 'moin-command-meta-shift-right)
  
  ;; Indent parents with subitems
  (check-func-at-point 'moin-command-meta-shift-right
  		       " * Yours\n * My item \n  * Subitem 1\n  * Subitem 2\n   * Subitem 2.1" 13 14
  		       " * Yours\n  * My item \n   * Subitem 1\n   * Subitem 2\n    * Subitem 2.1")
  (check-func-at-point 'moin-command-meta-shift-right
  		       " * Yours\n * My item \n  * Subitem 1\n  * Subitem 2\n   * Subitem 2.1" 36 36
  		       " * Yours\n * My item \n  * Subitem 1\n   * Subitem 2\n    * Subitem 2.1"))


(ert-deftest test--moin-list-indent-subtree-error ()
  "Tests `moin-command-meta-shift-right' for lists in negative cases"

  (test--moin-list-indentation-error 'moin-command-meta-shift-right))


(defun test--moin-list-outdentation-no-subtree(command)
  "Checks list outdentation with or without subtree on items that do not
have a subtree, the behavior for both commands must be the same."
  
  ;; Items without subitems, without multiline items
  (check-func-at-point command
  		       " * My item \n  * Yours" 18 17 " * My item \n * Yours")
  (check-func-at-point command
  		       " * My item \n  * Yours\n" 13 13 " * My item \n * Yours\n")
  (check-func-at-point command
  		       " * My item \n  * Yours\n * third" 18 17 " * My item \n * Yours\n * third")
  (check-func-at-point command
  		       "Text before\n * My item \n  * Yours\nText behind" 27 26
  		       "Text before\n * My item \n * Yours\nText behind")
  ;; Outdent multiline items
  (check-func-at-point command
       " * My item\n  * Yours\n   \n \n \n * third" 20 19 " * My item\n * Yours\n  \n \n \n * third")
  (check-func-at-point command
  " * My item\n  * Yours\n   \n \n \n\t\n   \n * third" 20 19 " * My item\n * Yours\n  \n \n \n\t\n  \n * third")
  (check-func-at-point command
  		       "TextBefore\n * My item\n  * Yours\n   \n \n \n\t\n   \nText behind" 31 30 "TextBefore\n * My item\n * Yours\n  \n \n \n\t\n  \nText behind")
  ;; Outdent subitems
  (check-func-at-point command
  		       " * My item \n   * Subitem 1\n    * Subitem 1.1\n   * Subitem 2\n * Yours" 52 51
  		       " * My item \n   * Subitem 1\n    * Subitem 1.1\n  * Subitem 2\n * Yours")
  ;; Outdent items after previous higher level items (without and with tabs)
  (check-func-at-point command
  		       " * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n  * Yours" 71 70
  		       " * My item \n   * Subitem 1\n   * Subitem 2\n     * Subitem 2.1\n * Yours")
  (check-func-at-point command
  		       " * My item \n \t* Subitem 1" 17 16
  		       " * My item \n * Subitem 1"))


(defun test--moin-list-outdentation-error (command)
  "Tests list outdendation for any command in negative cases"
  
  (check-func-at-point-throws-error command
  		       " * My item" 9 'user-error)
  (check-func-at-point-throws-error command
  				    " * My item\n * My Subitem" 16 'user-error))
  

(ert-deftest test--moin-list-outdent-item ()
  "Tests `moin-command-meta-left' for lists"
  
  (test--moin-list-outdentation-no-subtree 'moin-command-meta-left))


(ert-deftest test--moin-list-outdent-item-error ()
  "Tests `moin-command-meta-left' for lists in negative cases"
  
  (check-func-at-point-throws-error 'moin-command-meta-left
  		       " * My item" 9 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-left
  				    " * My item\n * My Subitem" 16 'user-error)
  (check-func-at-point-throws-error 'moin-command-meta-left
  				    " * My item\n  * My Subitem\n   * My Subsubitem" 16 'user-error))


(ert-deftest test--moin-list-outdent-subtree ()
  "Tests `moin-command-meta-shift-left' for lists"
  (test--moin-list-outdentation-no-subtree 'moin-command-meta-shift-left)
  
  ;; Outdent parents with subitems
  (check-func-at-point 'moin-command-meta-shift-left
  		       " * Yours\n  * My item \n   * Subitem 1\n   * Subitem 2\n    * Subitem 2.1" 14 13
  		       " * Yours\n * My item \n  * Subitem 1\n  * Subitem 2\n   * Subitem 2.1")
  (check-func-at-point 'moin-command-meta-shift-left
  		       " * Yours\n * My item \n  * Subitem 1\n  * Subitem 2\n   * Subitem 2.1" 37 36
  		       " * Yours\n * My item \n  * Subitem 1\n * Subitem 2\n  * Subitem 2.1"))


(ert-deftest test--moin-list-outdent-subtree-error ()
  "Tests `moin-command-meta-shift-left' for lists in negative cases"
  
  (test--moin-list-outdentation-error 'moin-command-meta-shift-left))
