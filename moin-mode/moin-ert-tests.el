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


(defun test-moin--command-at-point-expects-error(command initial-text error initial-point &optional region-size)
  "Inserts the given text into a temporary buffer, then sets point to a specific
position, optionally selects a region, and finally calls an arbitrary command. 
It expects an error to be thrown."
  (with-temp-buffer
    (insert initial-text)
    (goto-char initial-point)

    ;; Set the region before executing the command
    (if region-size
	(progn
	  (set-mark-command nil)
	  (forward-char region-size)))
    
    (should-error (funcall command) :type error)))


(defun test-moin--command-at-point-changes-buffer(command initial-text initial-point expected-point expected-buffer &optional region-size args)
  "Inserts the given text into a temporary buffer, then sets point to a specific
position, optionally selects a region, and finally calls an arbitrary command. 
It expects the buffer content to be as given by expected-buffer, and the new point at 
the given expected location."
  (with-temp-buffer
    (moin-mode)
    (insert initial-text)
    (goto-char initial-point)
    (funcall command args)

    ;; Set the region before executing the command
    (if region-size
	(progn
	  (set-mark-command nil)
	  (forward-char region-size)))
    
    (should (equal expected-point (point)))
    (should (equal expected-buffer (buffer-string)))))


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
  (test-moin--command-at-point-expects-error 'moin-command-format-bold
					     "Text\narbitrary other test text" 'user-error 2 5)
  (test-moin--command-at-point-expects-error 'moin-command-format-bold
					     "Text\narbitrary other test text" 'user-error 3 7))


(ert-deftest test-moin-command-format-italic-error()
  "Tests proper error handling of `moin-command-format-italic'"
  (test-moin--command-at-point-expects-error 'moin-command-format-italic
					     "Text\narbitrary other test text" 'user-error 2 5)
  (test-moin--command-at-point-expects-error 'moin-command-format-italic
					     "Text\narbitrary other test text" 'user-error 3 7))


(ert-deftest test-moin-command-format-underline-error()
  "Tests proper error handling of `moin-command-format-underline'"
  (test-moin--command-at-point-expects-error 'moin-command-format-underline
					     "Text\narbitrary other test text" 'user-error 2 5)
  (test-moin--command-at-point-expects-error 'moin-command-format-underline
					     "Text\narbitrary other test text" 'user-error 3 7))


;; ==================================================
;; Testing heading functions


(ert-deftest test-moin-is-on-heading-p-when-on-heading-line ()
  "`moin-is-in-heading-p' must return t when point is on a heading line, even if the
end of the heading line is malformed."
  (test-moin--execute-on-heading 'moin-is-on-heading-p "= Heading 1 =" t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "== Heading 2 " t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "=== Heading 3" t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "==== Heading 4 =====" t)
  (test-moin--execute-on-heading 'moin-is-on-heading-p "===== Heading 5 =====" t))


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
  ;; First we check issuing the command at the end of a heading line
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
				"= Heading 1 =" 14 17 "= Heading 1 =\n=  =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
				"= Heading 1 =" 13 17 "= Heading 1 =\n=  =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
				"== Heading 2 ==" 13 20 "== Heading 2 ==\n==  ==\n")
  ;; Then we check issuing the command within the prefix,
  ;; but not directly at the beginning of a heading line, before any text
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
				"===== Heading 5 = = =" 4 29 "===== Heading 5 = = =\n=====  =====\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
				"== Heading 2" 4 17 "== Heading 2\n==  ==\n")
  ;; Then we check issuing the command at the beginning of a heading line
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
				"=== Heading 3 " 1 5 "===  ===\n=== Heading 3 ")
  ;; Then we check issuing the command within the heading text
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
				"= Heading 1 =" 4 17 "= H =\n= eading 1 =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
				"== Heading 2 ==" 11 20 "== Heading ==\n==  2 ==\n")
  ;; Then we check issuing the command somewhere arbitrary behind a previous heading
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
      "== Heading 2 ==\nblindtext\nother text" 22 26 "== Heading 2 ==\nblind\n==  ==\ntext\nother text")
  ;; Finally we check issuing the command before any other heading
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
	   "Text before heading\n== Heading 2 ==" 14 17 "Text before h\n=  =\neading\n== Heading 2 ==")
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
	   "Text before heading" 2 5 "T\n=  =\next before heading"))


(ert-deftest test-moin-command-insert-heading-respect-content()
  "Checks `moin-command-insert-heading-respect-content'"
  ;; Check the behaviour in case the current section has no sub-headings, and might
  ;; have contents and siblings
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
					      "= Heading 1 =" 14 17 "= Heading 1 =\n=  =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
					      "= Heading 1 =\n\nAny text behind\nother text\n\n\n" 10 47
					      "= Heading 1 =\n\nAny text behind\nother text\n\n\n=  =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
					      "= Heading 1.1 =\n= Heading 1.2 =\n" 5 19
					      "= Heading 1.1 =\n=  =\n= Heading 1.2 =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
      "= Heading 1.1 =\nAny Text here and there\n\nAnd another line of text\n= Heading 1.2 =\n" 3 69
      "= Heading 1.1 =\nAny Text here and there\n\nAnd another line of text\n=  =\n= Heading 1.2 =\n")
  
  ;; Check the behaviour in case the current section has multiple sub-headings and a
  ;; sibling heading afterwards, and point is somewhere between the first character of the heading
  ;; and the first character of the next child heading
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
   "== Heading 2.1 ==\n\nAny text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===\n== Heading 2.2 ==" 12 81
   "== Heading 2.1 ==\n\nAny text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===\n==  ==\n== Heading 2.2 ==")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
   "= Heading 1.1 =\nAny text\n== Heading 2.1 ==\nany further text\n== Heading 2.2 ==\nText Text Blindtext\n\n= Heading 1.2 =" 21 102
   "= Heading 1.1 =\nAny text\n== Heading 2.1 ==\nany further text\n== Heading 2.2 ==\nText Text Blindtext\n\n=  =\n= Heading 1.2 =")

  ;; Check the behaviour in case the current section has multiple sub-headings, but no
  ;; sibling heading afterwards, and point is somewhere between the first character of the heading
  ;; and the first character of the next child heading
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
   "== Heading 2.1 ==\n\nAny text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===" 12 81
   "== Heading 2.1 ==\n\nAny text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===\n==  ==\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
   "= Heading 1.1 =\nAny text\n== Heading 2.1 ==\nany further text\n== Heading 2.2 ==\nText Text Blindtext\n\n" 21 102
   "= Heading 1.1 =\nAny text\n== Heading 2.1 ==\nany further text\n== Heading 2.2 ==\nText Text Blindtext\n\n=  =\n")

  ;; Check the behaviour in case point is at the beginning of a heading line
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
  				"= Heading 1 =" 1 3 "=  =\n= Heading 1 =")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
   "First text\n== Heading 2 ==\n\nAny subtree text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===" 12 15
   "First text\n==  ==\n== Heading 2 ==\n\nAny subtree text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===")
  
  ;; Check the behaviour in case point is before the first heading (if any at all)
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
				"" 1 3 "=  =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
				"Text" 3 8 "Text\n=  =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
				"\n\nText\nOther Text\nYetanothertext\n\n\n" 10 38
				"\n\nText\nOther Text\nYetanothertext\n\n\n=  =\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-insert-heading-respect-content
   "First text\n== Heading 2 ==\n\nAny subtree text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ===" 6 15
   "First text\n==  ==\n== Heading 2 ==\n\nAny subtree text\n=== Heading 3.1 ===\nany text\n=== Heading 3.2 ==="))


(ert-deftest test-moin-change-level-without-subtree()
  "Checks `moin-command-meta-left' and `moin-command-meta-right'
connection with each other."
  (test-moin--check-change-level 'moin-command-meta-left 'moin-command-meta-right
						 "" "Heading 1" "" "" 1 5)
  (test-moin--check-change-level 'moin-command-meta-left 'moin-command-meta-right
						 "" "Heading 1" "" "" 1 1)
  (test-moin--check-change-level 'moin-command-meta-left 'moin-command-meta-right
						 "Anytext before\n" "Heading 2" "\nAny text behind" "" 2 19)
  (test-moin--check-change-level 'moin-command-meta-left 'moin-command-meta-right
	 "Anytext before\n" "Heading 3" "\nAny text behind\n==== H4.1 ====\nsubtext\n==== H4.2 ====\n" "=== H3 ===\n" 3 19))


(ert-deftest test-moin-change-level-with-subtree()
  "Checks `moin-command-meta-shift-left' and `moin-command-meta-shift-right'
connection with each other."
  (test-moin--check-change-level 'moin-command-meta-shift-left 'moin-command-meta-shift-right
						 "" "Heading 1" "" "" 1 5)
  ;; (test-moin--check-change-level 'moin-command-meta-shift-left 'moin-command-meta-shift-right
  ;; 						 "" "Heading 1" "" "" 1 1)
  ;; (test-moin--check-change-level 'moin-command-meta-shift-left 'moin-command-meta-shift-right
  ;; 						 "Anytext before\n" "Heading 2" "\nAny text behind" "" 2 19)
  ;; (test-moin--check-change-level 'moin-command-meta-left 'moin-command-meta-right
  ;; 	 "Anytext before\n" "Heading 3" "\nAny text behind\n==== H4.1 ====\nsubtext\n==== H4.2 ====\n" "=== H3 ===\n" 3 19))
  )


(defun test-moin--make-heading (heading-text level)
  "Creates and returns a new heading with the given text
on the given level"
  (setq heading-pre-suf (make-string level ?=))
  (concat heading-pre-suf " " heading-text " " heading-pre-suf))


(defun test-moin--check-change-level(command-left command-right pre-text heading-text
			    subtree post-text start-level start-pos &optional subtree-change-func)
  "Inserts any prefix text, then a heading-text with the given start level
(should be on its own line, the prefix and postfix text must contain the
corresponding line breaks) as well as a postfix text into a new temporary
buffer, then goes to the specified start position (which should be on the
heading line) and executes a number of change level commands. Then it checks
their outcome."
  (with-temp-buffer
    (moin-mode)

    ;; Build the initial buffer contents
    (setq heading-line (test-moin--make-heading heading-text start-level))

    (insert
     (concat pre-text heading-line
     	 subtree post-text))
    (goto-char start-pos)
    (setq expect-point-at-bol-p (<= (current-column) start-level))

    (test-moin--repeat-change-level command-right '<
         moin-const-max-heading-level '+ start-level subtree-change-func)
    (test-moin--repeat-change-level command-left  '>
         1                            '- moin-const-max-heading-level subtree-change-func)))

;; TODO: Test `moin-command-meta-shift-left' for headings, i.e. demote incl. subtree
;; TODO: Test `moin-command-meta-shift-right' for headings, i.e. promote incl. subtree
;; TODO: Test `moin-command-meta-up' for headings, i.e. move up
;; TODO: Test `moin-command-meta-down' for headings, i.e. move down
;; TODO: Test `moin-command-tab' for headings, i.e. outline cycle 


(defun test-moin--repeat-change-level (command compare-func compare-level change-func curr-level &optional subtree-change-func)
  "Repeatedly performs command at current point, as long as an invocation of compare-func, 
comparing curr-level with compare level is true. Within the loop, curr-level and curr-pos are
changed after the command call using change-func, and finally some checking of expected buffer
content is done. It additional can execute a subtree change function to transform the subtree 
in some expected way before comparing it with the actual buffer content."
  (setq curr-pos (point))
  (while (funcall compare-func curr-level compare-level)
    (funcall command)
    (message "test-moin--check-change-level: buffer after command call: %s" (buffer-string))
    (setq curr-level (funcall change-func curr-level 1))
    
    (setq heading-line (test-moin--make-heading heading-text curr-level))
    
    (setq curr-pos (funcall change-func curr-pos 1))
    
    ;; Point should not change by the command
    (if expect-point-at-bol-p
	(should (equal (point-at-bol) (point)))
      (should (equal curr-pos (point))))

    ;; We must not change point position as the test case goes
    ;; on into the next loop
    (save-excursion
      (beginning-of-line)
      (should (looking-at (concat "^" heading-line "$"))))
    
    ;; Rest of the buffer should be unchanged
    (should (equal (concat pre-text heading-line subtree post-text) (buffer-string))))

  ;; Another invocation must fail as we are already on lowest or highest level
  (should-error (funcall command) :type 'user-error))


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
  (test-moin--table-create-positive "Hallo" "Jens" "4x3" 15 "\n\n||  ||  ||  ||  ||\n||  ||  ||  ||  ||\n||  ||  ||  ||  ||\n")
  (test-moin--table-create-positive "Hallo\n" "" "2x4" 10 "||  ||  ||\n||  ||  ||\n||  ||  ||\n||  ||  ||\n\n")
  (test-moin--table-create-positive "" "Jens" "1x2" 4 "||  ||\n||  ||\n\n"))


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
  (test-moin--table-create-negative "0x1")
  (test-moin--table-create-negative "1x0")
  (test-moin--table-create-negative "ANY TExt")
  (test-moin--table-create-negative "x1")
  (test-moin--table-create-negative "xx1")
  (test-moin--table-create-negative "4x1x454")
  (test-moin--table-create-negative "Sx1"))


(defun test-moin--table-create-negative (size-string)
  (with-temp-buffer
    (should-error (funcall 'moin--table-create size-string) :type 'user-error)))


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
  (test-moin--check-fix-field 1 " T\\(.*\\)t " "New\\1Text" " New\\1Text "))


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
  "Tests `moin-command-tab' and `moin--table-next-field' in positive cases"
  ;; Just move to the next field of the same row, without any buffer changes
  (test-moin--table-next-field-positive "||  ||  ||" 4 8)
  (test-moin--table-next-field-positive "||  ||  ||" 3 8)
  (test-moin--table-next-field-positive "|| my text || another text ||  ||" 6 15)
  (test-moin--table-next-field-positive "|| my text || a ||\n|| bbbbbbb || cccc ||" 31 34)
  ;; Special case: Point before first field
  (test-moin--table-next-field-positive "||  ||  ||" 2 4)
  (test-moin--table-next-field-positive "||  ||  ||" 1 4)
  ;; Move point to next line if in last column, without any buffer changes
  (test-moin--table-next-field-positive "|| my text || a ||\n|| bbbbbbb || cccc ||" 15 23)
  (test-moin--table-next-field-positive "|| my text || a ||\n|| bbbbbbb || cccc ||" 16 23)
  (test-moin--table-next-field-positive "|| my text || a ||\n|| bbbbbbb || cccc ||" 17 23)
  ;; Special case: Point after last field of a line
  (test-moin--table-next-field-positive "|| my text || a ||\n|| bbbbbbb || cccc ||" 18 23)
  (test-moin--table-next-field-positive "|| my text || a ||\n|| bbbbbbb || cccc ||" 19 23)
  ;; Table whitespace corrections
  (test-moin--table-next-field-positive "|| || ||" 3 8 "||  ||  ||")
  (test-moin--table-next-field-positive "||  ||||" 4 8 "||  ||  ||")
  (test-moin--table-next-field-positive "||||||" 4 8 "||  ||  ||")
  (test-moin--table-next-field-positive "||  ||||" 1 4 "||  ||||")
  (test-moin--table-next-field-positive "|||| ||" 2 4 "||  || ||")
  (test-moin--table-next-field-positive "|| my text||a ||\n||bbbbbbb|| cccc ||" 15 22
   					"|| my text|| a ||\n|| bbbbbbb || cccc ||")
  (test-moin--table-next-field-positive "|| my text ||another text ||" 6 15 "|| my text || another text ||")
  (test-moin--table-next-field-positive "|| my text || another text||" 6 15 "|| my text || another text ||")
  (test-moin--table-next-field-positive "|| myt||a ||\n||bbbbbbb||cc  cc      ||\n||  	  	f || ||" 34 39
   					"|| myt||a ||\n||bbbbbbb|| cc  cc ||\n|| f || ||")
  ;; Create new line if issued in last field of table
  (test-moin--table-next-field-positive "||  ||" 4 11 "||  ||\n||  ||\n")
  (test-moin--table-next-field-positive "|| a |||| b ||\n|| c || || ||\nAny Text behind" 26 34 "|| a |||| b ||\n|| c || ||  ||\n||  ||  ||  ||\nAny Text behind")
  )


(defun test-moin--table-next-field-positive (text start-point expected-point &optional expected-buffer)
  (with-temp-buffer
    (moin-mode)
    (insert text)
    (goto-char start-point)
    (moin-command-tab)
    (message "test-moin--moin--table-next-field buffer string after funcall: %s" (buffer-string))
    
    (if expected-buffer
	(should (equal expected-buffer (buffer-string)))
      (should (equal text (buffer-string))))
    
    (should (equal expected-point (point)))))


(ert-deftest test-moin--table-insert-row ()
  "Tests `moin--table-insert-row'"
  ;; Inserting rows behind current row
  (test-moin--check-table-insert-row "|| ||" 1 'moin--table-insert-row nil "||  ||")
  (test-moin--check-table-insert-row "||||aaa ||" 9 'moin--table-insert-row nil "||  ||  ||")
  (test-moin--check-table-insert-row "||a||b||c||d||     e ||" 22 'moin--table-insert-row nil "||  ||  ||  ||  ||  ||")
  ;; Inserting rows before current row (direct call)
  (test-moin--check-table-insert-row "|| ||" 1 'moin--table-insert-row t "||  ||")
  (test-moin--check-table-insert-row "||||aaa ||" 9 'moin--table-insert-row t "||  ||  ||")
  (test-moin--check-table-insert-row "||a||b||c||d||     e ||" 22 'moin--table-insert-row t "||  ||  ||  ||  ||  ||")
  ;; Inserting rows before current row (command call)
  (test-moin--check-table-insert-row "|| ||" 1 'moin-command-meta-shift-down t "||  ||")
  (test-moin--check-table-insert-row "||||aaa ||" 9 'moin-command-meta-shift-down t "||  ||  ||")
  (test-moin--check-table-insert-row "||a||b||c||d||     e ||" 22 'moin-command-meta-shift-down t "||  ||  ||  ||  ||  ||"))


(defun test-moin--check-table-insert-row (text start-point func insert-before-p expected-new-row)
  (with-temp-buffer
    (moin-mode)
    (insert text)
    (goto-char start-point)
    (funcall func insert-before-p)
    (message "test-moin--check-table-insert-row buffer string after funcall: %s" (buffer-string))

    (if insert-before-p
	(progn
	  (should (equal (concat expected-new-row "\n" text) (buffer-string)))
	  (should (equal 4 (point))))
      (progn
	(should (equal (concat text "\n" expected-new-row) (buffer-string)))
	(should (equal (+ (length text) 5) (point)))))))


(ert-deftest test-moin--table-next-row ()
  "Tests `moin-command-table-next-row'"
  ;; Moves to the next field and fixes previous and target field
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "|| ab ||\n|| xy ||" 5 13 "|| ab ||\n|| xy ||")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "|| ||\n|| ||" 4 11 "||  ||\n||  ||")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "|| abc||def ||\n|| || gef||\nAny Text" 12 23
      "|| abc|| def ||\n|| || gef ||\nAny Text")
  ;; Inserts a new table row
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "||      ab ||    ||\n||||||" 23 33
      "||      ab ||    ||\n||  ||||\n||  ||  ||\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "||      ab ||    ||\nAny other text" 3 19
      "|| ab ||    ||\n||  ||  ||\nAny other text")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "||      ab ||    ||\nAny other text" 15 26
      "||      ab ||  ||\n||  ||  ||\nAny other text")
  ;; Inserts a newline when issued at start or end of line
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "|| ab ||\n|| xy ||" 1 2 "\n|| ab ||\n|| xy ||")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "|| ab ||\n|| xy ||" 9 10 "|| ab ||\n\n|| xy ||")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-next-row
      "|| ab ||\n|| xy ||" 10 11 "|| ab ||\n\n|| xy ||")
  )


(ert-deftest test-moin--table-next-row-error ()
  "Tests `moin-command-table-next-row' in error situations"
  (test-moin--command-at-point-expects-error
   'moin-command-table-next-row "|| abc||def ||\n|| ||" 'user-error  10))


(ert-deftest test-moin--table-copy-down ()
  "Tests `moin-command-table-copy-down'"
  ;; Moves to the next field, copies previous field content and fixes previous field
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "|| ab ||\n||||" 5 13 "|| ab ||\n|| ab ||")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "|| ||\n|| ||" 4 11 "||  ||\n||  ||")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "|| abc||def ||\n|| ||    ||\nAny Text" 12 23
      "|| abc|| def ||\n|| || def ||\nAny Text")
  ;; Replaces any content in target column
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "|| ab ||\n||xy||" 5 13 "|| ab ||\n|| ab ||")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "|| ab ||\n|| xy||" 5 13 "|| ab ||\n|| ab ||")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "|| ab ||\n||xy ||" 5 13 "|| ab ||\n|| ab ||")
  ;; Inserts a new table row
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "||      ab ||    ||\n||||||" 23 33
      "||      ab ||    ||\n||  ||||\n||  ||  ||\n")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "||      ab ||    ||\nAny other text" 3 19
      "|| ab ||    ||\n|| ab ||  ||\nAny other text")
  (test-moin--command-at-point-changes-buffer 'moin-command-table-copy-down
      "||      ab || bap||\nAny other text" 15 29
      "||      ab || bap ||\n||  || bap ||\nAny other text"))


(ert-deftest test-moin--table-copy-down-error ()
  "Tests `moin-command-table-copy-down' in error situations"
  ;; Malformed next row
  (test-moin--command-at-point-expects-error
   'moin-command-table-copy-down "|| abc||def ||\n|| ||" 'user-error  10)
  ;; Command not allowed at bol and eol
  (test-moin--command-at-point-expects-error
   'moin-command-table-copy-down "|| abc||def ||" 'user-error  1)
  (test-moin--command-at-point-expects-error
   'moin-command-table-copy-down "|| abc||def ||" 'user-error  15))


(ert-deftest test-moin--table-meta-return ()
  "Tests `moin-command-meta-return' in tables"
  ;; Moves to the next field, no split of previous field (end of field)
  ;; and fixes previous field
  (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
      "|| ab ||\n||||" 6 13 "|| ab ||\n||  ||")
  ;; (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
  ;;     "|| ||\n|| ||" 4 11 "||  ||\n||  ||")
  ;; ;; Splits content of current field down into (empty) target field
  ;; (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
  ;;     "||ab ||\n||||" 4 12 "|| a ||\n|| b ||")
  ;; (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
  ;;     "|| abc||def ||\n|| ||      ||\nAny Text" 9 20
  ;;     "|| abc||  ||\n|| || def ||\nAny Text")
  ;; ;; Prepends any content in target column
  ;; (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
  ;;     "|| ab ||\n||xy||" 5 13 "|| ab ||\n|| bxy ||")
  ;; (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
  ;;     "||ab ||\n|| xy    dfsdfsd ||" 3 10 "|| ||\n|| abxy    dfsdfsd ||")
  ;; ;; Inserts a new table row
  ;; (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
  ;;     "||      ab ||    ||\n||||||" 23 33
  ;;     "||      ab ||    ||\n||  ||||\n||  ||  ||\n")
  ;; (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
  ;;     "||r      ab ||    ||\nAny other text" 4 18
  ;;     "|| r ||    ||\n|| ab ||  ||\nAny other text")
  ;; (test-moin--command-at-point-changes-buffer 'moin-command-meta-return
  ;;     "||      ab || bap||\nAny other text" 17 28
  ;;     "||      ab || ba ||\n||  || p ||\nAny other text")
  )


(ert-deftest test-moin--meta-return-error ()
  "Tests `moin-command-meta-return' in error situations"
  ;; ;; Malformed next row
  ;; (test-moin--command-at-point-expects-error
  ;;  'moin-command-meta-return "|| abc||def ||\n|| ||" 'user-error  10)
  ;; ;; Command not allowed at bol and eol
  ;; (test-moin--command-at-point-expects-error
  ;;  'moin-command-meta-return "|| abc||def ||" 'user-error  1)
  ;; (test-moin--command-at-point-expects-error
  ;;  'moin-command-meta-return "|| abc||def ||" 'user-error  15)
  )

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


(ert-deftest test-moin--get-list-item-info ()
  "Tests the behaviour of `moin--list-get-item-info' against a test buffer."

  (setq expected (list
		  (list 1 (list 1 4 " " "*" " "))
		  (list 16 (list 10 13 " " "." " "))
		  (list 20 (list 19 21 " " "." ""))
		  (list 37 (list 22 27 "   " "*" " "))
		  (list 39 (list 38 43 "   " "1." ""))
		  (list 39 (list 38 43 "   " "1." ""))
		  (list 58 (list 46 51 "   " "A." ""))
		  (list 67 (list 46 51 "   " "A." ""))
		  (list 73 (list 46 51 "   " "A." ""))
		  (list 76 (list 46 51 "   " "A." ""))
		  (list 107 (list 96 115 "                  " "." ""))
		  (list 124 (list 116 122 "		  " "1." ""))
		  (list 127 (list 125 129 " " "22." ""))))
  
  (test-moin--execute-on-file "auto_test_lists.txt" 'test-moin--check-list-get-item-info expected))


(defun test-moin--check-list-get-item-info(expected)
  (dolist (current-item expected)
    (goto-char (car current-item))
    (should (equal (car (cdr current-item)) (moin--list-get-item-info)))))


(ert-deftest test-moin--get-list-item-info-error ()
  "Tests the behaviour of `moin--list-get-item-info' if not in a list."
  (test-moin--command-at-point-expects-error 'moin--list-get-item-info "arbitrary other test text" 'user-error 10)
  (test-moin--command-at-point-expects-error 'moin--list-get-item-info "A. sadasdasd" 'user-error 1)
  (test-moin--command-at-point-expects-error 'moin--list-get-item-info "*" 'user-error 2))


(ert-deftest test-moin--list-insert-item-same-level--point-after-item-text()
   "Tests `moin--list-insert-item-same-level': For various bullet types and indentations before and after the current bullet, and with point currently behind text of the item - Is expected to create a new item after the current one, with same bullet and indentation before and after bullet, no text after that."
   (test-moin--check-insert-item-same-level--point-after-item-text " * " "Text")
   (test-moin--check-insert-item-same-level--point-after-item-text " *" "t")
   (test-moin--check-insert-item-same-level--point-after-item-text " A.   " "a")
   (test-moin--check-insert-item-same-level--point-after-item-text " i." "My text")
   (test-moin--check-insert-item-same-level--point-after-item-text " ." "another text")
   (test-moin--check-insert-item-same-level--point-after-item-text " o.  	" "\n  \n\n looney item"))


(defun test-moin--check-insert-item-same-level--point-after-item-text(item-prefix item-text)
  (with-temp-buffer
    (insert (concat item-prefix item-text))
    (setq start-point (point))
    (moin--list-insert-item-same-level)
    (message "Buffer string after test method call:\n%s" (buffer-string))
    (should (equal (+ start-point (length item-prefix) 1) (point)))
    (should (equal t (eolp)))
    (should (equal item-prefix (buffer-substring-no-properties (+ start-point 1) (point))))))


(ert-deftest test-moin--list-insert-item-same-level--point-before-item-text()
   "Tests `moin--list-insert-item-same-level': For various bullet types and indentations before and after the current bullet, and with point currently before the text of the item - Is expected to create a new item before the current one, with same bullet and indentation before and after bullet, no text after that on the same line."
   (test-moin--check-insert-item-same-level--point-before-item-text " * " "Text")
   (test-moin--check-insert-item-same-level--point-before-item-text " *" "")
   (test-moin--check-insert-item-same-level--point-before-item-text " A.   " "a")
   (test-moin--check-insert-item-same-level--point-before-item-text " i." "My text")
   (test-moin--check-insert-item-same-level--point-before-item-text " ." "another text")
   (test-moin--check-insert-item-same-level--point-before-item-text " o.	" "\n  \n\n looney item"))


(defun test-moin--check-insert-item-same-level--point-before-item-text(item-prefix item-text)
  (dotimes (start-point (+ 1 (length item-prefix)))
    (with-temp-buffer
      (insert (concat item-prefix item-text))
      (goto-char start-point)
      (moin--list-insert-item-same-level)
      (message "Buffer string after %s test method call(s):\n%s" start-point (buffer-string))
      (should (equal (+ (length item-prefix) 1) (point)))
      (should (equal t (eolp)))
      (should (equal item-prefix (buffer-substring-no-properties 1 (point)))))))


(ert-deftest test-moin--list-insert-item-same-level--point-within-item-text()
   "Tests `moin--list-insert-item-same-level': For various bullet types and indentations before and after the current bullet, and with point currently within the text of the item - Is expected to create a new item after the current one, with same bullet and indentation before and after bullet, with the text of the current item after point as text of the new item."
   (test-moin--check-insert-item-same-level--point-within-item-text " * " "Text")
   (test-moin--check-insert-item-same-level--point-within-item-text " A.   " "a")
   (test-moin--check-insert-item-same-level--point-within-item-text " i." "My text")
   (test-moin--check-insert-item-same-level--point-within-item-text " ." "another text")
   (test-moin--check-insert-item-same-level--point-within-item-text " o.	" "\n  \n\n looney item"))


(defun test-moin--check-insert-item-same-level--point-within-item-text(item-prefix item-text)
  (dotimes (i (- (length item-text) 1))
    (with-temp-buffer
      (insert (concat item-prefix item-text))
      (setq start-point (+ (length item-prefix) i 2))
      (goto-char start-point)
      (moin--list-insert-item-same-level)
      (message "Buffer string after %s test method call(s):\n%s" (+ i 1) (buffer-string))
      (should (equal (+ (length item-prefix) start-point 1) (point)))
      (should (equal item-prefix (buffer-substring-no-properties (+ start-point 1) (point))))
      (setq expected-new-item-text (substring item-text (+ i 1)))
      (should (equal expected-new-item-text (buffer-substring-no-properties (point) (+ (point) (- (length item-text) i 1))))))))


(ert-deftest test-moin--get-list-item-info-error ()
  "Tests the behaviour of `moin--list-insert-item-same-level' if not in a list."
  (test-moin--command-at-point-expects-error 'moin--list-insert-item-same-level "arbitrary other test text" 'user-error 10)
  (test-moin--command-at-point-expects-error 'moin--list-insert-item-same-level "A. sadasdasd" 'user-error 1)
  (test-moin--command-at-point-expects-error 'moin--list-insert-item-same-level "*" 'user-error 2))


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
