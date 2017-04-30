;;; moin-mode.el --- Major mode and command definition for MoinMoin (main file)

;; Copyright (C) 2017 Jens Ebert

;; Author: Jens Ebert <jensebert@gmx.net>
;; Maintainer: Jens Ebert <jensebert@gmx.net>
;; Created: 20 Jan 2017
;; Keywords: wiki editing
;; Version: 0.4

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

;; Overview:
;; ---------
;; This is moin-mode which targets to provide a rich editing feeling for
;; MoinMoin 1.9.x wiki pages. See <https://moinmo.in/> for more information
;; regarding MoinMoin. The major editing facilities and syntax highlighting
;; is designed to be quite similar to org mode 8.x.
;; It is possible yet not guaranteed that this mode will work as expected
;; also with other versions of MoinMoin markup, namely Moin 1.8 and below.
;;
;; This major mode tries to make the rather outdated moinmoin-mode.el as found
;; on the following page obsolete:
;; <https://moinmo.in/EmacsForMoinMoin>
;;
;; This is an entirely new major mode for MoinMoin, created from the ground up
;; but surely inspired by the existing work.
;;
;; Installation:
;; -------------
;; * Ensure the file `moin-mode.el' and all its accompanying files are located
;; in Emacs load path, if this is not the case, use `add-to-list' in your Emacs
;; initialization file, e.g. to .emacs:
;;   (add-to-list 'load-path /my/dir)
;; * Add the following line to your Emacs initialization file:
;;   (require 'moin-mode)
;;
;; User documentation & configuration:
;; -----------------------------------
;; For more details on how to use and configure `moin-mode', see
;; the documentation of the `moin-mode' major mode by typing
;;   M-x describe-function [RET] moin-mode
;; in Emacs. Before this, ensure `moin-mode' is installed as
;; described above.
;;
;; Requirements:
;; -------------
;;
;; * Requires minimum Emacs version 24.0
;;
;; Tests:
;; ------
;; This module has been tested with all combinations of:
;; * OS: Windows 10
;; * Emacs: 24.5
;; * MoinMoin: 1.9.x
;;
;; Improvements/Known issues:
;; -------------------------
;; * WikiWords are also highlighted in headings, links and environments
;; * Syntax highlighting of multiline environments sometimes does not work
::
;; If you have any further suggestions for improvements or enhancements,
;; please mail to <jensebert@gmx.net>

;;; Change Log:
;;
;; v0.1    2017-01-20  Jens Ebert            <jensebert@gmx.net>
;; - initial draft
;; v0.2    2017-02-12  Jens Ebert            <jensebert@gmx.net>
;; - Removed dependency to outshine: outshine introduced subtle bugs for
;;   subtree moving and made it impossible to rebind meta-shift-
;;   <up|down|left|right>
;; - Implemented outline-cycle using bare outline mode commands
;; - Fixed issues in moving subtrees introduced by Emacs outline bug 19102
;;   (for Emacs 24.x, bugfix for bug 19102 from Emacs 25.1 is used)
;; - Fixed some issues with syntax highlighting (errors in *messages*)
;; - Updated outline cycle to also work for headings without any content
;; - Implemented moving of subtrees for headings (up and down)
;; v0.3    2017-03-23  Jens Ebert            <jensebert@gmx.net>
;; - Fixed issue with italic syntax highlighting
;; - Implemented promotion and demotion of subtrees
;; - Updated outline cycle to also work in a special case of sub-headings
;;   without content
;; v0.4    2017-03-26  Jens Ebert            <jensebert@gmx.net>
;; - Implemented creation of new headings
;; - Modularization of moin-mode
;; v0.5    2017-04-30  Jens Ebert            <jensebert@gmx.net>
;; - Added first list functions

;;; Code:
;; ==================================================
;; Required mandatory packages

(require 'moin-faces)
(require 'moin-headings)
(require 'moin-tables)
(require 'moin-lists)

;; ==================================================
;; Group definitions
(defgroup moin nil
  "Major mode for MoinMoin 1.9.x wiki pages"
  :prefix "moin-")

;; ==================================================
;; Global customization options

;; None so far - But see individual other modules and docs for other options

;; ==================================================
;; Constants

;; None so far - But see individual other modules and docs for other constants

;; ==================================================
;; "Private" Functions
(defun moin--setup-key-bindings ()
  "Installs all key bindings"

  ;; Structure editing redefined to org key-bindings and reassociated
  (define-key moin-mode-map (kbd "M-S-<up>") 'moin-command-meta-shift-up)
  (define-key moin-mode-map (kbd "M-S-<down>") 'moin-command-meta-shift-down)
  (define-key moin-mode-map (kbd "M-<up>") 'moin-command-meta-up)
  (define-key moin-mode-map (kbd "M-<down>") 'moin-command-meta-down)

  ;; Promotion / Demotion or table column editing
  (define-key moin-mode-map (kbd "M-S-<left>") 'moin-command-meta-shift-left)
  (define-key moin-mode-map (kbd "M-S-<right>") 'moin-command-meta-shift-right)
  (define-key moin-mode-map (kbd "M-<left>") 'moin-command-meta-left)
  (define-key moin-mode-map (kbd "M-<right>") 'moin-command-meta-right)

  ;; Inserting new elements
  (define-key moin-mode-map (kbd "M-<return>") 'moin-command-meta-return)
  (define-key moin-mode-map (kbd "C-<return>") 'moin-command-insert-heading-respect-content)
  (define-key moin-mode-map (kbd "<return>") 'moin-command-table-next-row)
  
  ;; Moving in tables or Outline cycle (a.k.a. visibility cycling)
  (define-key moin-mode-map [tab] 'moin-command-tab)
  (define-key moin-mode-map (kbd "S-<tab>") 'moin-command-table-previous-field)

  ;; Specific list commands
  (define-key moin-mode-map (kbd "C-c C-b") 'moin-command-create-bullet-list)
  (define-key moin-mode-map (kbd "C-c C-n") 'moin-command-create-numbered-list)

  ;; Formatting commands
  (define-key moin-mode-map (kbd "C-c C-f C-b") 'moin-command-format-bold)
  (define-key moin-mode-map (kbd "C-c C-f C-i") 'moin-command-format-italic)
  (define-key moin-mode-map (kbd "C-c C-f C-u") 'moin-command-format-underline))


;; ==================================================
;; Functions

(defun moin-print-object-at-point()
  "Helper function to check which object is currently at point, just for debbuging purpose"
  (interactive)
  (if (moin-is-in-table-p)
      (message "TABLE")
    (if (moin-is-in-list-p)
	(message "LIST")
      (if (moin-is-on-heading-p)
	  (message "HEADING")
	(message "NONE")))))


(defun moin-format (formatting-prefix-and-suffix)
  "Formats the current region with an arbitrary single line MoinMoin formatting.
  Alternatively, if there is no region, inserts the fornmatting prefixes and
  suffixes and places point between them. If the region spans multiple lines, it issues an error message, as MoinMoin does not support formatting to
span multiple lines. It does not check if it is already in a formatted area."
  (interactive "p")
  (setq prefix-suffix-len (length formatting-prefix-and-suffix))
  
  (if (region-active-p)
      (progn
	(setq start-point (region-beginning))
	(setq end-point (region-end))

	(goto-char end-point)

	;; Special case: One full line is selected, and end of region actually
	;; is on beginning of the next line. count-lines returns 1 in that case,
	;; but this also would result in multi-line formattings.
	(if (or (> (count-lines start-point end-point) 1) (bolp))
	    (user-error "Cannot format region spanning multiple lines"))
	
	(goto-char start-point)
	(insert formatting-prefix-and-suffix)
	(goto-char (+ end-point prefix-suffix-len))
	(insert formatting-prefix-and-suffix))
    (progn
	(insert formatting-prefix-and-suffix)
	(insert formatting-prefix-and-suffix)))
  
  (backward-char prefix-suffix-len))


;; ==================================================
;; Commands

(defun moin-command-meta-shift-up (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it basically does the same thing 
as `outline-move-subtree-up': It moves the subtree of the 
current heading to the point before the previous heading of the same 
level, if any. If there is no such heading, it prints an error message. 
* If point is currently in a table, it removes the current row of the
table.
* If point is currently in a list, it moves the current item with its
subtree up (swapping with previous item), if it is not already the first
item below its parent item."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-remove-row arg)
    (if (moin-is-in-list-p)
	(moin--list-move-subtree-up arg)
      (if (moin-is-on-heading-p)
	  (moin--heading-move-subtree-up-or-down (- arg))))))


(defun moin-command-meta-shift-down (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it basically does the same thing 
as `outline-move-subtree-down': It moves the subtree of the 
current heading to the point after the previous heading of the same 
level, if any. If there is no such heading, it prints an error message.
* If point is currently in a table, it creates a new row before the 
current row of the table.
* If point is currently in a list, it moves the current item with its
subtree down (swapping with next item), if it is not already the last
item below its parent item."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-insert-row arg)
    (if (moin-is-in-list-p)
	(moin--list-move-subtree-down arg)
      (if (moin-is-on-heading-p)
	  (moin--heading-move-subtree-up-or-down arg)))))


(defun moin-command-meta-up (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it performs the same funtion as 
`moin-command-meta-shift-up', see there. 
* If point is currently in a list, it performs the same function as 
`moin-command-meta-shift-up', see there. 
* If point is currently in a table, it moves the current row up (swapping 
with previous row), if it is not already the first row in the table."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-move-row-up arg)
    (if (or (moin-is-in-list-p) (moin-is-on-heading-p))
	(moin-command-meta-shift-up arg))))


(defun moin-command-meta-down (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it performs the same funtion as 
`moin-command-meta-shift-down', see there. 
* If point is currently in a list, it performs the same function as 
`moin-command-meta-shift-down', see there. 
* If point is currently in a table, it moves the current row down (swapping 
with next row), if it is not already the last row in the table."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-move-row-down arg)
    (if (or (moin-is-in-list-p) (moin-is-on-heading-p))
	(moin-command-meta-shift-down arg))))


(defun moin-command-meta-shift-left (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it promotes the current subtree (i.e.
the current heading and all its children), if the current heading is not
already on level 1. This command does not work with an active mark is active,
which will lead to an error message. It also fixes errors in the end marker 
of the heading, if necessary.
* If point is currently in a table, it removes the current column of the
table.
* If point is currently in a list, it decreases the indentation of the
current item with its subtree (i.e. all its children). A subtree's indentation
can only be decreased if it is not already on the left-most indentation level of 
the list."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-remove-column arg)
    (if (moin-is-in-list-p)
	(moin--list-outdent-subtree arg)
      (if (moin-is-on-heading-p)
	  (moin--heading-change-level 'moin--heading-do-promote t)))))


(defun moin-command-meta-shift-right (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it demotes the current subtree (i.e.
the current heading and all its children), if the current heading is not
already on level 5. This command does not work with an active mark is active,
which will lead to an error message. It also fixes errors in the end marker 
of the heading, if necessary.
* If point is currently in a table, it inserts a new empty column to the 
left of point.
* If point is currently in a list, it increases the indentation of the
current item with its subtree (i.e. all its children). An item's indentation
can only be increased if it is not the first item below its parent."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-insert-column arg)
    (if (moin-is-in-list-p)
	(moin--list-indent-subtree arg)
      (if (moin-is-on-heading-p)
	  (moin--heading-change-level 'moin--heading-do-demote t)))))


(defun moin-command-meta-left (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it demotes the current heading, leaving
its children unchanged, but only if the current heading is not already on level 1. 
This command does not work with an active mark is active,
which will lead to an error message. It also fixes errors in the end marker 
of the heading, if necessary.
* If point is currently in a table, it moves the current column of the
table to the left, but only if it is not already the left-most column.
* If point is currently in a list, it decreases the indentation, leaving its
children unchanged. A single item's indentation can only be decreased if it is
not already on the left-most indentation level of the list. Furthermore, if the
item has children, its indentation can only be decreased by one."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-move-column-left arg)
    (if (moin-is-in-list-p)
	(moin--list-outdent-item arg)
      (if (moin-is-on-heading-p)
	  (moin--heading-change-level 'moin--heading-do-promote nil)))))


(defun moin-command-meta-right (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it promotes the current heading, leaving
its children unchanged, but only if the current heading is not already on level 5. 
This command does not work with an active mark is active,
which will lead to an error message. It also fixes errors in the end marker 
of the heading, if necessary.
* If point is currently in a table, it moves the current column of the
table to the right, but only if it is not already the right-most column.
* If point is currently in a list, it increases the indentation, leaving its
children unchanged. An item's indentation can only be increased if it is not the
first item below its parent."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-move-column-right arg)
    (if (moin-is-in-list-p)
	(moin--list-indent-item arg)
      (if (moin-is-on-heading-p)
	  (moin--heading-change-level 'moin--heading-do-demote nil)))))


(defun moin-command-meta-return (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently in a table, it moves to the next row, splitting 
the content of the current field in two parts starting at point, if point
is currently in the middle of the field. It creates a new row if point is
currently in the last row. In contrast to org mode, selection or prefix
arguments are not considered, there is no specific functionality for this.
* If point is currently in a list, it inserts a new item with the same
level as the one at point. If the comamnd is used in the middle of a list item,
it is split and the text after point is taken as text of the new item. 
The new item is then inserted after the item at point. If point is
currently before the item, the new item is inserted before the current 
item instead.
* Otherwise, including the case that point is currently on a heading, it
inserts a new heading with the same level as the one at point. If the 
command is used in the middle of a heading line, it is split and the text
after point is taken as text of the new heading. The new heading is then 
inserted after the heading at point. If point is currently before the heading,
the new heading is inserted before the current heading instead. If point 
is not in a heading line, the new heading is inserted at point, at the same 
level of the first heading before point. An error message is given if
there is no heading before point."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-next-row-split-field arg)
    (if (moin-is-in-list-p)
	(moin--list-insert-item-same-level arg)
      ;; else insert a new headline
      (moin--heading-insert arg))))


(defun moin-command-insert-heading-respect-content (&optional arg)
  "Inserts a new heading with the same level of the current heading, 
right after the subtree of the current heading. This also works when only
in the body of a heading's section."
  (interactive "p")
  (moin--heading-insert-respect-content arg))


(defun moin-command-table-next-row (&optional arg)
  "When in a table, moves to the next row. On the end of a line, it 
still does NEWLINE and thus can be used to split a table."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-next-row arg)
    ;; else: Not in table, simply newline
    (newline)))


(defun moin-command-table-previous-field (&optional arg)
  "When in a table, moves to the previous field, if any. The previous field is
 the field to the left of the current one, or in case that the current field 
is in the left-most column, the last field of the previous row."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-previous-field arg))
  ;; TODO: Redirect to global binding here?
  ;;(call-interactively (global-key-binding "S-\t"))
  )


(defun moin-command-create-bullet-list (&optional arg)
  "Create a new bullet-point list at the line after point. If currently already
in a list, this has a similar effect as using `moin-command-meta-return' to insert
a new list item, with two major differences: Firstly the new item will be 
inserted as top-level item, and secondly it will not respect the type of the 
previous top-level item, but always inserts a bullet-point item. Thus, you should use 
this command really only to create a new list, and if you are already in a list, 
use `moin-command-meta-return' instead."
  (interactive "p")
  (moin--list-insert-item moin-const-bullet-list))


(defun moin-command-create-numbered-list (&optional arg)
  "Create a new numbered list at the line after point. If currently already
in a list, this has a similar effect as using `moin-command-meta-return' to insert
a new list item, with two major differences: Firstly the new item will be 
inserted as top-level item, and secondly it will not respect the type of the 
previous top-level item, but always inserts a numbered item. Thus, you should use 
this command really only to create a new list, and if you are already in a list, 
use `moin-command-meta-return' instead."
  (interactive "p")
  (moin--list-insert-item moin-const-numbered-list))


(defun moin-command-tab (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently in a table, it moves to the next field to the right,
or to the first field of the next row, if the current field is in the last
column of the table. If the current field is the last field of the table
in the right-most column, this command will create a new empty row and put
point into the left-most field of the new row.
* If point is currently on a heading, it performs visibility cycling. It 
cycles the current heading level between three states:
 * FOLDED: Hides the entire subtree and content of the current heading
 * CHILDREN: Shows the content of the current heading and all direct child 
headings of the next lower level below the current heading. The child heading
subtrees remain hidden.
 * SUBTREE: The entire content and subtree below the current heading is 
shown entirely, no folding.
* Otherwise delegates to the global binding for TAB."
  (interactive "p")
  (if (moin-is-in-table-p)
      (moin--table-next-field arg)
    (if (moin-is-on-heading-p)
	(moin--heading-outline-cycle arg)
      (call-interactively (global-key-binding "\t")))))


(defun moin-command-format-bold (&optional arg)
  "Formats current region or point bold. See `moin-format' for details. This command is basic in a sense that it does not check if it is already in a formatted area."
  (interactive "p")
  (moin-format "'''"))


(defun moin-command-format-italic (&optional arg)
  "Formats current region or point italic. See `moin-format' for details. This command is basic in a sense that it does not check if it is already in a formatted area."
  (interactive "p")
  (moin-format "''"))


(defun moin-command-format-underline (&optional arg)
  "Formats current region or point as underlined. See `moin-format' for details. This command is basic in a sense that it does not check if it is already in a formatted area."
  (interactive "p")
  (moin-format "__"))


;; ==================================================
;; Major mode definition

(define-derived-mode moin-mode outline-mode "moin"
  "Set major mode for editing MoinMoin pages"
  ;; Preparations for outline minor mode
  (make-local-variable 'outline-regexp)
  (setq outline-regexp "=+ ")
  ;; Setup related modes
  (toggle-truncate-lines 0)
  (visual-line-mode 1)
  ;; Setup moin internal data
  (moin--setup-key-bindings)
  (moin--setup-font-lock))

;; This is the default naming of revision files for moin moin
;; wiki articles, when saved in file system
(add-to-list 'auto-mode-alist '("[0-9]+\\'" . moin-mode))

;; ==================================================
;; Provide package

(provide 'moin-mode)

;;; moin-mode.el ends here
