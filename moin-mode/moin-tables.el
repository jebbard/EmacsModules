;;; moin-tables.el --- Table support for moin mode

;; Copyright (C) 2017 Jens Ebert

;; Author: Jens Ebert <jensebert@gmx.net>
;; Maintainer: Jens Ebert <jensebert@gmx.net>
;; Created: 26 Mar 2017
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

;; Table support for moin mode

;;; Code


;; ==================================================
;; Constants

(defconst moin-const-table-default-size "5x2"
  "The default size of a new table in moin mode.")

(defconst moin-const-table-delimiter "||"
  "The MoinMoin table delimiter.")

(defconst moin-const-quoted-table-delimiter
  (regexp-quote moin-const-table-delimiter)
  "The MoinMoin table delimiter in a regexp quoted form.")


;; ==================================================
;; Functions

(defun moin-is-in-table-p ()
  "Is point on a table line?"
  (save-excursion
    (beginning-of-line)
    (looking-at (concat moin-const-quoted-table-delimiter
			".*?" moin-const-quoted-table-delimiter))))


;; ==================================================
;; "Private" Functions

(defun moin--table-next-row (&optional arg)
  "See `moin-command-table-next-row' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (if (eolp)
      (newline)
    (progn
      (user-error "Not implemented yet!"))))


(defun moin--table-next-row-split-field (&optional arg)
  "See `moin-command-meta-return' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (if (eolp)
      (newline)
    (progn
      (user-error "Not implemented yet!"))))


(defun moin--table-previous-field (&optional arg)
  "See `moin-command-table-previous-field' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  ;; It seems impossible to redirect to the mysterious key "S-tab" or also
  ;; called "<backtab>" or "BACKTAB", so we assume nobody needs this...
  (user-error "Not implemented yet!"))


(defun moin--table-next-field (&optional arg)
  "See `moin-command-tab' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (if (> current-column 1)
      (progn
	(re-search-forward (regexp-quote moin-const-table-delimiter))
;; TODO implement
	)
    ))


(defun moin--table-move-column-right (&optional arg)
  "See `moin-command-meta-right' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (user-error "Not implemented yet for tables!"))


(defun moin--table-move-column-left (&optional arg)
  "See `moin-command-meta-left' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (user-error "Not implemented yet for tables!"))


(defun moin--table-insert-column (&optional arg)
  "See `moin-command-meta-shift-right' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (user-error "Not implemented yet for tables!"))


(defun moin--table-remove-column (&optional arg)
  "See `moin-command-meta-shift-left' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (user-error "Not implemented yet for tables!"))


(defun moin--table-move-row-down (&optional arg)
  "See `moin-command-meta-down' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (user-error "Not implemented yet for tables!"))


(defun moin--table-move-row-up (&optional arg)
  "See `moin-command-meta-up' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (user-error "Not implemented yet for tables!"))


(defun moin--table-insert-row (&optional arg)
  "See `moin-command-meta-shift-down' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (user-error "Not implemented yet for tables!"))


(defun moin--table-remove-row (&optional arg)
  "See `moin-command-meta-shift-up' for more information.
Expects to actually be in a table as prerequisite. Never call this 
function if point is currently not in a table."
  (user-error "Not implemented yet for tables!"))


(defun moin--table-determine-column-details ()
  "Determines the column details of the current row. Expects to actually 
be in a table as prerequisite. Never call this function if point is 
currently not in a table.

The column details are presented in a list containing the following
* The first element is the current table column, i.e. the 1-based logical
column index in the current row where point is currently in, which then can
also be used as index on this entire returned list for getting the current
column details. In the special case that point is located before the first
column content starts, the current-column is nevertheless set to 1. In all 
other cases where point is in between the two delimiters '||' of the moin
table (including the case where point is behind the last character of the last
field of the current row), it is seen to be still located in previous column.
* All other entries have the form (start-point end-point content) where 'start-point' is 
an integer with the buffer's point value of the first character directly after
'||', i.e. where the column content begins, 'end-point' is an integer with the buffer's 
point value after the last character directly before '||', i.e. where the column ends,
and 'content' is the actual string content of the column, including any enclosing
whitespace, but without the column delimiters '||'."
  (interactive)
  (setq column-regex
	(concat moin-const-quoted-table-delimiter
		"\\(.*?\\)" moin-const-quoted-table-delimiter))
  (setq column-delimiter-size (length moin-const-table-delimiter))
  
  (save-excursion
    (setq initial-point (point))
    (beginning-of-line)
    (setq current-column 1)
    (setq return-list (list))

    (while (and (looking-at column-regex) (< (+ (point) column-delimiter-size) (point-at-eol)))
      (setq start-point (match-beginning 1))

      ;; Special case: Point is exactly in the middle of the table delimiter '||'
      ;; i.e. behind previous field end point and before next field start point
      (if (and (> current-column 1) (> initial-point end-point) (< initial-point start-point))
	  (add-to-list 'return-list (- current-column 1)))
      
      (setq end-point (match-end 1))
      (setq content (match-string 1))

      (if (and (>= initial-point start-point) (<= initial-point end-point))
	  (add-to-list 'return-list current-column))

      (setq column-details (list start-point end-point content))
      (setq return-list (append return-list (list column-details)))
      (goto-char end-point)
      (setq current-column (+ current-column 1)))
    
    (if (< initial-point 3)
	(add-to-list 'return-list 1)
      (if (> initial-point (- (point-at-eol) 2))
	  (add-to-list 'return-list (- current-column 1)))))

  return-list)


(defun moin--table-create (table-size-string)
  (setq error-message (concat "Invalid table size format specified, should be Columns x Rows [e.g. " moin-const-table-default-size "]"))

  (setq table-size-list (split-string table-size-string "x" t nil))

  (if (not (eq (length table-size-list) 2))
      (user-error error-message))

  (setq cols (string-to-number (car table-size-list)))
  (setq rows (string-to-number (car (cdr table-size-list))))

  ;; This includes the case of invalid row or column string
  (if (or (< cols 1) (< rows 1))
      (user-error error-message))

  (if (bolp)
      (progn
	(newline)
	(previous-line))
    (progn
      (end-of-line)
      (newline)
      (newline)))

  (setq point-before-table (point))
  
  (dotimes (row rows)
    (dotimes (col cols)
      (insert moin-const-table-delimiter)
      (insert "  "))
    (insert moin-const-table-delimiter)
    (newline))

  (goto-char (+ point-before-table 3)))


;; ==================================================
;; Provide package

(provide 'moin-tables)

;;; moin-tables.el ends here
