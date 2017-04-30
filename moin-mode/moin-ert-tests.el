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


(defun test-moin--command-at-point-expects-error(command text error set-point &optional region-size)
  "Inserts the given text into a temporary buffer, then sets point to a specific
position, optionally selects a region, and finally calls an arbitrary command. 
It expects an error to be thrown."
  (with-temp-buffer
    (insert text)
    (goto-char set-point)

    ;; Set the region before executing the command
    (if region-size
	(progn
	  (set-mark-command nil)
	  (forward-char region-size)))
    
    (should-error (funcall command) :type error)))

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
    (should (equal (substring text 0 (- formatting-start-point 1)) (buffer-substring-no-properties 1 formatting-start-point)))
    ;; Check markup start
    (should (equal markup (buffer-substring-no-properties formatting-start-point (+ formatting-start-point markup-len))))
    ;; Check formatted text (within markup) - must be unchanged
    (should (equal (substring text (- formatting-start-point 1) (- formatting-end-point 1)) (buffer-substring-no-properties (+ formatting-start-point markup-len)  new-formatting-end-point)))
    ;; Check markup end
    (should (equal markup (buffer-substring-no-properties new-formatting-end-point (+ new-formatting-end-point markup-len))))
    ;; Check text after formatted text - must be unchanged
    (should (equal (substring text (- formatting-end-point 1)) (buffer-substring-no-properties (+ new-formatting-end-point markup-len) (point-at-eol))))))


(ert-deftest test-moin-command-format-bold-error()
  "Tests proper error handling of `moin-command-format-bold'"
  (test-moin--command-at-point-expects-error 'moin-command-format-bold "Text\narbitrary other test text" 'user-error 2 5)
  (test-moin--command-at-point-expects-error 'moin-command-format-bold "Text\narbitrary other test text" 'user-error 3 7))


(ert-deftest test-moin-command-format-italic-error()
  "Tests proper error handling of `moin-command-format-italic'"
  (test-moin--command-at-point-expects-error 'moin-command-format-italic "Text\narbitrary other test text" 'user-error 2 5)
  (test-moin--command-at-point-expects-error 'moin-command-format-italic "Text\narbitrary other test text" 'user-error 3 7))


(ert-deftest test-moin-command-format-underline-error()
  "Tests proper error handling of `moin-command-format-underline'"
  (test-moin--command-at-point-expects-error 'moin-command-format-underline "Text\narbitrary other test text" 'user-error 2 5)
  (test-moin--command-at-point-expects-error 'moin-command-format-underline "Text\narbitrary other test text" 'user-error 3 7))


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


(ert-deftest test-moin--heading-determine-section-level-error ()
  "`moin--heading-determine-section-level' must throw a user error if currently in a section
without a heading before."
  (test-moin--command-at-point-expects-error 'moin--heading-determine-section-level "Any text" 'error 1)
  (test-moin--command-at-point-expects-error 'moin--heading-determine-section-level "Any text" 'error 2)
  (test-moin--command-at-point-expects-error 'moin--heading-determine-section-level "Any text" 'error 5)
  (test-moin--command-at-point-expects-error 'moin--heading-determine-section-level "Any text\n= Heading =" 'error 7))


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
    (should (equal expected-suffix (buffer-substring-no-properties (+ level text-len 2) (+ level level text-len 3))))))


;; ==================================================
;; Testing table functions

;; TODO

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
