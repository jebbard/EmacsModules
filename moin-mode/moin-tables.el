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



;; ==================================================
;; Provide package

(provide 'moin-tables)

;;; moin-tables.el ends here
