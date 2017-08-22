;;; moin-mode.el --- Major mode for MoinMoin (main file)

;; Copyright (C) 2017 Jens Ebert

;; Author: Jens Ebert <jensebert@gmx.net>
;; Maintainer: Jens Ebert <jensebert@gmx.net>
;; Created: 20 Jan 2017
;; Keywords: wiki editing
;; Version: 0.8

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
;; This is moin-mode which targets to provide a rich editing feeling
;; for MoinMoin 1.9.x wiki pages.  See <https://moinmo.in/> for more
;; information regarding MoinMoin.  The major editing facilities and
;; syntax highlighting is designed to be quite similar to org mode
;; 8.x.  It is possible, yet not guaranteed, that this mode will work
;; as expected also with other versions of MoinMoin markup, namely
;; Moin 1.8 and below.
;;
;; This major mode aims to replace the rather outdated
;; moinmoin-mode.el as found on the following page:
;; <https://moinmo.in/EmacsForMoinMoin>
;;
;; This is an entirely new major mode for MoinMoin, created from the
;; ground up but surely inspired by the existing work of moimmoin
;; mode.
;;
;; Installation:
;; -------------
;; * Ensure the file `moin-mode.el' and all its accompanying files are
;; located in Emacs load path, if this is not the case, use
;; `add-to-list' in your Emacs initialization file, e.g. in .emacs:
;;
;;   (add-to-list 'load-path /my/dir)
;;
;; * Add the following line to your Emacs initialization file:
;;
;;   (require 'moin-mode)
;;
;; User documentation & configuration:
;; -----------------------------------
;; For more details on how to use and configure `moin-mode', see the
;; documentation of the `moin-mode' major mode by typing
;;
;;   M-x describe-function [RET] moin-mode
;;
;; in Emacs.  Before this, ensure `moin-mode' is installed as described
;; above.
;;
;; Requirements:
;; -------------
;;
;; * Requires minimum Emacs version 24.4
;;
;; Tests:
;; ------
;; This module has been tested with all combinations of:
;; * OS: Windows 10
;; * Emacs: 24.4, 24.5
;; * MoinMoin: 1.9.x
;;
;; Improvements/Known issues:
;; -------------------------
;; * WikiWords are also highlighted in headings, links and
;;   environments
;; * Syntax highlighting of multiline environments sometimes does not
;;   work
;;
;; If you have any further suggestions for improvements or enhancements,
;; please mail to <jensebert@gmx.net>

;;; Change Log:
;;
;; v0.1    2017-01-20  Jens Ebert            <jensebert@gmx.net>
;; - initial draft
;; v0.2    2017-02-12  Jens Ebert            <jensebert@gmx.net>
;; - Removed dependency to outshine: outshine introduced subtle bugs
;;   for subtree moving and made it impossible to rebind meta-shift-
;;   <up|down|left|right>
;; - Implemented outline-cycle using bare outline mode commands
;; - Fixed issues in moving subtrees introduced by Emacs outline bug
;;   19102 (for Emacs 24.x, bugfix for bug 19102 from Emacs 25.1 is
;;   used)
;; - Fixed some issues with syntax highlighting (errors in *messages*)
;; - Updated outline cycle to also work for headings without any
;;   content
;; - Implemented moving of subtrees for headings (up and down)
;; v0.3    2017-03-23  Jens Ebert            <jensebert@gmx.net>
;; - Fixed issue with italic syntax highlighting
;; - Implemented promotion and demotion of subtrees
;; - Updated outline cycle to also work in a special case of
;;   sub-headings without content
;; v0.4    2017-03-26  Jens Ebert            <jensebert@gmx.net>
;; - Implemented creation of new headings
;; - Modularization of moin-mode
;; v0.5    2017-04-30  Jens Ebert            <jensebert@gmx.net>
;; - Added first list functions
;; v0.6    2017-05-04  Jens Ebert            <jensebert@gmx.net>
;; - Various automated tests and bugfixes for headings, tables, lists
;; - Table creation
;; v0.7    2017-05-14  Jens Ebert            <jensebert@gmx.net>
;; - Various table next row commands
;; - Table next field and table previous field
;; v0.8    2017-06-10  Jens Ebert            <jensebert@gmx.net>
;; - Finished all table and list commands including unittests
;; - Moin mode feature-complete for v1.0
;; v0.9    2017-07-02  Jens Ebert            <jensebert@gmx.net>
;; - Cleaned all flycheck warnings (except unnecessary documentation warnings)
;; - Cleaned all elint warnings

;;; Code:
;; ==================================================
;; Required mandatory packages

(require 'moin-faces)
(require 'moin-headings)
(require 'moin-tables)
(require 'moin-lists)
(require 'outline)

;; ==================================================
;; Group definitions
(defgroup moin nil
  "Major mode for MoinMoin 1.9.x wiki pages"
  :group 'editing
  :prefix "moin-")

;; ==================================================
;; Global customization options

(defcustom moin-double-line-break-p t
  "Set to t to enable that whenever you hit enter outside of tables,
two instead of just one line break is added. This ensures that you
have a real MoinMoin line break, because MoinMoin interpretes a single
newline as space and not as line break."
  :group 'moin)

;; See also individual other modules and docs for other
;; options

;; ==================================================
;; Constants

;; None so far - But see individual other modules and docs for other
;; constants

;; ==================================================
;; "Private" Functions
(defun moin--setup-key-bindings (moin-mode-map)
  "Installs all key bindings into MOIN-MODE-MAP."

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
  (define-key moin-mode-map (kbd "<return>") 'moin-command-return)
  (define-key moin-mode-map (kbd "S-<return>") 'moin-command-table-copy-down)
  
  ;; Moving in tables or Outline cycle (a.k.a. visibility cycling)
  (define-key moin-mode-map [tab] 'moin-command-tab)
  (define-key moin-mode-map (kbd "S-<tab>") 'moin-command-table-previous-field)

  ;; Specific table commands
  (define-key moin-mode-map (kbd "C-c |") 'moin-command-create-table)

  ;; Specific list commands
  (define-key moin-mode-map (kbd "C-c C-b") 'moin-command-create-bullet-list)
  (define-key moin-mode-map (kbd "C-c C-n") 'moin-command-create-numbered-list)

  ;; Formatting commands
  (define-key moin-mode-map (kbd "C-c C-f C-b") 'moin-command-format-bold)
  (define-key moin-mode-map (kbd "C-c C-f C-i") 'moin-command-format-italic)
  (define-key moin-mode-map (kbd "C-c C-f C-e") 'moin-command-format-italic)
  (define-key moin-mode-map (kbd "C-c C-f C-u") 'moin-command-format-underline))


;; ==================================================
;; Functions

(defun moin-print-object-at-point()
  "Helper function to check which object is currently at point, just
for debbuging purpose"
  (interactive)
  (if (moin-is-in-table-p)
      (message "TABLE")
    (if (moin-is-in-list-p)
	(message "LIST")
      (if (moin-is-on-heading-p)
	  (message "HEADING")
	(message "NONE")))))


(defun moin-format (formatting-prefix-and-suffix)
  "Formats the current region with an arbitrary single line MoinMoin
formatting. Alternatively, if there is no region, inserts the
FORMATTING-PREFIX-AND-SUFFIX and places point between them. If the
region spans multiple lines, it throws an error, as MoinMoin does not
support formatting to span multiple lines. It does not check if it is
already in a formatted area."
  (let
      ((prefix-suffix-len (length formatting-prefix-and-suffix))
       start-point end-point)

    (if (region-active-p)
	(progn
	  (setq start-point (region-beginning))
	  (setq end-point (region-end))

	  (goto-char end-point)

	  ;; Special case (second part of or): One full line is
	  ;; selected, and end of region actually is on beginning of
	  ;; the next line. count-lines returns 1 in that case, but
	  ;; this also would result in multi-line formattings.
	  (if (or (> (count-lines start-point end-point) 1) (bolp))
	      (user-error "Cannot format region spanning multiple lines"))
	  
	  (goto-char start-point)
	  (insert formatting-prefix-and-suffix)
	  (goto-char (+ end-point prefix-suffix-len))
	  (insert formatting-prefix-and-suffix))
      (progn
	(insert formatting-prefix-and-suffix)
	(insert formatting-prefix-and-suffix)))
    
    (backward-char prefix-suffix-len)))


;; ==================================================
;; Commands

(defun moin-command-meta-shift-up ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently on a heading, it basically does the same
   thing as `outline-move-subtree-up': It moves the subtree of the
   current heading to the point before the previous heading of the
   same level, if any. If there is no such heading, it throws an
   error.
 * If point is currently in a table, it removes the current row of the
   table.
 * If point is currently in a list, it moves the current item with its
   subtree up (swapping with previous item), if it is not already the
   first item below its parent item."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-remove-row)
    (if (moin-is-in-list-p)
	(moin--list-move-subtree-up)
      (if (moin-is-on-heading-p)
	  (moin--heading-move-subtree-up-or-down -1)))))


(defun moin-command-meta-shift-down ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently on a heading, it basically does the same
   thing as `outline-move-subtree-down': It moves the subtree of the
   current heading to the point after the previous heading of the same
   level, if any. If there is no such heading, it throws an error.
 * If point is currently in a table, it creates a new row before the
   current row of the table. Positions point within the first field of
   the new row.
 * If point is currently in a list, it moves the current item with its
   subtree down (swapping with next item), if it is not already the
   last item below its parent item."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-insert-row t)
    (if (moin-is-in-list-p)
	(moin--list-move-subtree-down)
      (if (moin-is-on-heading-p)
	  (moin--heading-move-subtree-up-or-down 1)))))


(defun moin-command-meta-up ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently on a heading, it performs the same funtion as
   `moin-command-meta-shift-up', see there.
 * If point is currently in a list, it performs the same function as
   `moin-command-meta-shift-up', see there.
 * If point is currently in a table, it moves the current row up
   (swapping with previous row), if it is not already the first row in
   the table."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-move-row-up)
    (if (moin-is-in-list-p)
	(moin--list-move-subtree-up)
      (if (moin-is-on-heading-p)
	  (moin--heading-move-subtree-up-or-down -1)))))


(defun moin-command-meta-down ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently on a heading, it performs the same funtion as
   `moin-command-meta-shift-down', see there.
 * If point is currently in a list, it performs the same function as
   `moin-command-meta-shift-down', see there.
 * If point is currently in a table, it moves the current row down
   (swapping with next row), if it is not already the last row in the
   table."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-move-row-down)
    (if (moin-is-in-list-p)
	(moin--list-move-subtree-down)
      (if (moin-is-on-heading-p)
	  (moin--heading-move-subtree-up-or-down 1)))))


(defun moin-command-meta-shift-left ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently on a heading, it promotes the current subtree
   (i.e. the current heading and all its children), if the current
   heading is not already on level 1. This command does not work with
   an active region, which will lead to an error being thrown. It also
   fixes errors in the end marker of the heading, if necessary.
 * If point is currently in a table, it removes the current column of
   the table. Point is placed at the beginning of the next column, if
   any. If there is no next column, it is placed at the beginning of
   the previous column, if any.
 * If point is currently in a list, it decreases the indentation of
   the current item with its subtree (i.e. all its children) by just
   removing one blank. A subtree's indentation can only be decreased
   if it is not already on the left-most indentation level of the
   list. If any item in the current subtree spans over multiple lines,
   one blank is removed from each line, unless there is just a single
   blank left which is always kept. Point is kept before the current
   character, however, if point is at start of line, it remains
   there."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-remove-column)
    (if (moin-is-in-list-p)
	(moin--list-outdent-subtree)
      (if (moin-is-on-heading-p)
	  (moin--heading-change-level 'moin--heading-do-promote t -1)))))


(defun moin-command-meta-shift-right ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently on a heading, it demotes the current subtree
   (i.e. the current heading and all its children), if the current
   heading is not already on level 5. This command does not work with
   an active region, which will lead to an error being thrown. It also
   fixes errors in the end marker of the heading, if necessary.
 * If point is currently in a table, it inserts a new empty column to
   the left of the current column. Point is placed within the same row
   and the beginning of the new column.
 * If point is currently in a list, it increases the indentation of
   the current item with its subtree (i.e. all its children) by just
   adding one blank. An item's indentation can only be increased if it
   is not the first item below its parent. If any item in the current
   subtree item spans over multiple lines, one blank is added at the
   beginning of each line. Point is usually kept before the current
   character. However, if point is at start of line, it remains
   there."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-insert-column)
    (if (moin-is-in-list-p)
	(moin--list-indent-subtree)
      (if (moin-is-on-heading-p)
	  (moin--heading-change-level 'moin--heading-do-demote t +1)))))


(defun moin-command-meta-left ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently on a heading, it demotes the current heading,
   leaving its children unchanged, but only if the current heading is
   not already on level 1. This command does not work with an active
   mark, which will lead to an error being thrown. It also fixes
   errors in the end marker of the heading, if necessary.
 * If point is currently in a table, it moves the current column of
   the table to the left, but only if it is not already the left-most
   column. After movement, point is set to be at the start of the
   column directly behind the column delimiter.
 * If point is currently in a list, it decreases the indentation by
   just removing one blank, leaving its children unchanged. A single
   item's indentation can only be decreased if it is not already on
   the left-most indentation level of the list. Furthermore, if the
   item has children, its indentation cannot be decreased. Use
   `moin-command-meta-shift-left' in this case instead. If the item
   spans over multiple lines, one blank is removed from each line of
   the item, unless there is just a single blank left which is always
   kept. Point is kept before the current character, except when point
   is at start of line, in which case it remains there."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-move-column-left)
    (if (moin-is-in-list-p)
	(moin--list-outdent-item)
      (if (moin-is-on-heading-p)
	  (moin--heading-change-level 'moin--heading-do-promote nil -1)))))


(defun moin-command-meta-right ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently on a heading, it promotes the current
   heading, leaving its children unchanged, but only if the current
   heading is not already on level 5. This command does not work with
   an active mark, which will lead to an error being thrown. It also
   fixes errors in the end marker of the heading, if necessary.
 * If point is currently in a table, it moves the current column of
   the table to the right, but only if it is not already the
   right-most column.
 * If point is currently in a list, it increases the indentation by
   just adding one blank, leaving its children unchanged. An item's
   indentation can only be increased if it is not the first item below
   its parent. If the item spans over multiple lines, one blank is
   added at the beginning of each line of the item. Point is usually
   kept before the current character. However, if point is at start of
   line, it remains there."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-move-column-right)
    (if (moin-is-in-list-p)
	(moin--list-indent-item)
      (if (moin-is-on-heading-p)
	  (moin--heading-change-level 'moin--heading-do-demote nil +1)))))


(defun moin-command-meta-return ()
  "Context-sensitive command that performs different functions based
on the context:
 * If point is currently in a table, it moves to the next row,
   splitting the content of the current field in two parts starting at
   point, if point is currently in the middle of the field. If there
   is a next row, and the field in the next row already contains text,
   this text is prepended by the text split from the current row's
   field. If there is no next row, this command creates a new row. For
   the current as well as the target field, it ensures that - after
   moving to the next field - there is just exactly one blank after
   the previous and before the next column separator. Issued at the
   end or start of a line, this command throws an error. In contrast
   to org mode, selection or prefix arguments are not considered,
   there is no specific functionality for this.
 * If point is currently in a list, it inserts a new item with the
   same level as the one at point. If the command is used in the
   middle of a list item, it is split and the text after point is
   taken as text of the new item. The new item is then inserted after
   the item at point. If point is currently before the item, the new
   item is inserted before the current item instead.
 * Otherwise, including the case that point is currently on a heading,
   it inserts a new heading with the same level as the one at point or
   the current section's heading. If there is no heading before point,
   it inserts a heading with level 1. If the command is used in the
   middle of a heading line, it is split and the text after point is
   taken as text of the new heading. The new heading is then inserted
   after the heading at point. If point is in a heading line, but
   before the first character of the heading text, the new heading is
   inserted before the current heading. If point is not in a heading
   line, the new heading is inserted at point, at the same level of
   the first heading before point. An error is thrown if there is no
   heading before point."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-next-row "SPLIT")
    (if (moin-is-in-list-p)
	(moin--list-insert-item-same-level)
      ;; else insert a new headline
      (moin--heading-insert))))


(defun moin-command-insert-heading-respect-content()
  "Inserts a new heading with the same level of the current heading,
right after the subtree of the current heading. This also works when
only in the body of a heading's section. If point is on the heading
line and at the beginning of line, the new heading is created directly
before the current heading. In any other case it is created after the
subtree of the current heading. If there is no heading at or before
point, it tries to find the next section, and inserts a new heading
with the same level directly before it. If there is no heading at all
in the current buffer, it goes to the end of buffer and inserts a new
heading line of level 1."
  (interactive)
  (moin--heading-insert-respect-content))


(defun moin-command-return()
  "When in a table, moves to the next row. If there is no next row,
this command creates a new row. For both the current as well as the
field below where this command moves to, it ensures that - after
moving to the next field - there is just exactly one blank after the
previous and before the next column separator. On the end or start of
a line, it still does a line break and thus can be used to split a
table. If not within a table, this command inserts two line breaks
instead of just one, in case that `moin-double-line-break-p' is t.
This feature was especially added for moin-mode to ensure a line break
is also shown as this in MoinMoin itself. MoinMoin interpretes a
single newline as a space and only two newlines is displayed as a line
break. If you do not like this behavior, set
`moin-double-line-break-p' to nil."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-next-row "BASIC")
    
    (if moin-double-line-break-p
	(newline))
    
    (newline)))


(defun moin-command-table-copy-down ()
  "When in a table, moves to the next row and copies the content of
the current field down. If the next row already contains text in the
field below, this text is replaced by the copied text. If there is no
next row, this command creates a new row. For the current field, it
ensures that - after moving to the next field - there is just one
blank after the previous and before the next column separator. On the
end or start of a line, this command throws an error."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-next-row "COPY")
    ;; else: Not in table, simply newline
    (newline)))


(defun moin-command-table-previous-field ()
  "When in a table, moves to the previous field, if any. The previous
 field is the field to the left of the current one, or in case that
 the current field is in the left-most column, the last field of the
 previous row. In contrast to `moin-command-tab' in tables, it will
 not prepend a new row in case point is currently in the very first
 field of the table. If the previous field already contains text, this
 command positions point just before the first non-whitespace
 character of the field. After moving to the previous field - for both
 the current as well as the previous field - this command ensures that
 there is just exactly one blank after the previous and before the
 next column separator."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-previous-field)
    (user-error "This command can only be used in tables")))


(defun moin-command-create-bullet-list ()
  "Create a new bullet-point. If point is at the end of line, it
inserts a new line after point and creates a new list on the next
line. If point is not at the end of the line, it splits the current
line at point and takes the remainder of the current line as content
of the first item in the new list. If point is at the beginning of
line, it turns the current line into a list item. If currently already
in a list, this has a similar effect as using
`moin-command-meta-return' to insert a new list item, with two major
differences: First, the new item will be inserted as top - level item,
and second it will not respect the type of the previous top - level
item, but always inserts a bullet-point item. Thus, you should use
this command really only to create a new list, and if you are already
in a list, use `moin-command-meta-return' instead."
  (interactive)
  (moin--list-insert-item moin-const-bullet-list))


(defun moin-command-create-numbered-list ()
  "Create a new numbered list. If point is at the end of line, it
inserts a new line after point and creates a new list on the next
line. If point is not at the end of the line, it splits the current
line at point and takes the remainder of the current line as content
of the first item in the new list. If point is at the beginning of
line, it turns the current line into a list item. If currently already
in a list, this has a similar effect as using
`moin-command-meta-return' to insert a new list item, with two major
differences: First, the new item will be inserted as top - level item,
and second it will not respect the type of the previous top - level
item, but always inserts a numbered item. Thus, you should use this
command really only to create a new list, and if you are already in a
list, use `moin-command-meta-return' instead."
  (interactive)
  (moin--list-insert-item moin-const-numbered-list))


(defun moin-command-tab ()
  "Context-sensitive command that performs different functions based
on the context:
  * If point is currently in a table, it moves to the next table field
    to the right, or to the first field of the next row, if the
    current field is in the last column of the table. If the current
    field is the last field of the table in the right-most column,
    this command will create a new empty row and put point into the
    left-most field of the new row. If the next field already
    constains text, this command positions point just before the first
    non-whitespace character of the field. After moving to the next
    field - for both the current as well as the next field - this
    command ensures that there is just exactly one blank after the
    previous and before the next column separator.
 * If point is currently on a heading, it performs visibility cycling.
   It cycles the current heading level between three states:
   * FOLDED: Hides the entire subtree and content of the current
     heading
   * CHILDREN: Shows the content of the current heading and all direct
     child headings of the next lower level below the current heading.
     The child heading subtrees remain hidden.
   * SUBTREE: The entire content and subtree below the current heading
     is shown entirely, no folding.
 * Otherwise delegates to the global binding for TAB."
  (interactive)
  (if (moin-is-in-table-p)
      (moin--table-next-field)
    (if (moin-is-on-heading-p)
	(moin--heading-outline-cycle)
      (call-interactively (global-key-binding "\t")))))


(defun moin-command-format-bold ()
  "Formats current region or point bold. See `moin-format' for
details. This command is basic in a sense that it does not check if it
is already in a formatted area."
  (interactive)
  (moin-format moin-const-format-bold))


(defun moin-command-format-italic ()
  "Formats current region or point italic. See `moin-format' for
details. This command is basic in a sense that it does not check if it
is already in a formatted area."
  (interactive)
  (moin-format moin-const-format-italic))


(defun moin-command-format-underline ()
  "Formats current region or point as underlined. See `moin-format'
for details. This command is basic in a sense that it does not check
if it is already in a formatted area."
  (interactive)
  (moin-format moin-const-format-underline))


(defun moin-command-create-table ()
  "Creates a new moin-style table with the given number of rows and
columns. If point is at beginning of line, the table is created before
the current line, and a newline is inserted between table and text. If
point is not at the beginning of line, the table is created after the
current line, and a newline is inserted between text and table."
  (interactive 
   (let (table-size-string)
     (setq table-size-string
	   (read-string
	    (concat "Table size Columns x Rows [e.g. "
		    moin-const-table-default-size "]: ")
	    "" nil moin-const-table-default-size))

     (moin--table-create table-size-string))))


;; ==================================================
;; Major mode definition

(define-derived-mode moin-mode outline-mode "moin"
  "Set major mode for editing MoinMoin pages"
  ;; Preparations for outline minor mode
  (make-local-variable 'outline-regexp)
  (setq outline-regexp "=\\{1,5\\}")
  ;; Setup related modes
  (toggle-truncate-lines 0)
  (visual-line-mode 1)
  ;; Setup moin internal data
  (moin--setup-key-bindings moin-mode-map)
  (moin--setup-font-lock))

;; This is the default naming of revision files for moin moin
;; wiki articles, when saved in file system
(add-to-list 'auto-mode-alist '("[0-9]+\\'" . moin-mode))

;; ==================================================
;; Provide package

(provide 'moin-mode)

;;; moin-mode.el ends here
