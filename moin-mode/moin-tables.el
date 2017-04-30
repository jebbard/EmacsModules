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
;; Functions

(defun moin-is-in-table-p ()
  "Is point on a table line?"
  (save-excursion
    (beginning-of-line)
    (looking-at "||")))


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
  (user-error "Not implemented yet for tables!"))


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

(defconst moin--table-delimiter "||"
  "Delimiter used to identify MoinMoin tables")

(defun moin--table-determine-column-details ()
  "Determines the column details of the current row. Expects to actually 
be in a table as prerequisite. Never call this function if point is 
currently not in a table.

The column details are presented in a list containing the following
* The first element is the current table colum, i.e. the logical column in
the current row where point is currently in; if the table is consisting of 0
columns, it contains a 0 and the list has only this single element; otherwise
it contains the 1-based column index, which then can also be used on this
entire returned list for getting the current column details
* All other entries have the form (start-point end-point content) where 'start-point' is 
an integer with the buffer's point value of the first character directly after
'||', i.e. where the column content begins, 'end-point' is an integer with the buffer's 
point value adter the last character directly before '||', i.e. where the column ends,
and 'content' is the actual string content of the column, including any enclosing
whitespace, but without the column delimiters '||'."
  (interactive)
  (setq column-regex (concat moin--table-delimiter "\\(.*?\\)" moin--table-delimiter))
  (setq column-deliminter-size (length moin--table-delimiter))
  (setq return-list (list ()))
  
  (save-excursion
    (beginning-of-line)
    (setq current-point (point))
    (while (< (+ current-point column-deliminter-size) (point-at-eol))
      (if (looking-at column-regex)
	  (progn
	    (setq start-point (match-beginning 1))
	    (setq end-point (match-end 1))
	    (setq content (match-string 1))
	    (message "START %s" start-point)
	    (message "END %s" end-point)
	    (message "CONTENT %s" content)

	    (setq column-details '(start-point end-point content))
	    
	    (setq (append return-list column-details))
	    (setq current-point end-point)
            (goto-char current-point)
	    )
	(setq current-point (point-at-eol)))))

  (message "LIST: %s" return-list)

  return-list)


;; ==================================================
;; Provide package

(provide 'moin-tables)

;;; moin-tables.el ends here
