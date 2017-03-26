;;; moin-lists.el --- List support for moin mode

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

;; List support for moin mode

;;; Code

;; ==================================================
;; Functions

(defun moin-is-in-list-p ()
  "Is point on a list line?"
  (save-excursion
    (beginning-of-line)
    (looking-at "\\s-+\\([*.]\\|[1-9A-Za-z]\\.\\)")))


;; ==================================================
;; "Private" Functions

(defun moin--list-insert-item (&optional arg)
  "See `moin-command-meta-return' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (user-error "Not implemented yet for lists!"))


(defun moin--list-indent-item (&optional arg)
  "See `moin-command-meta-right' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (user-error "Not implemented yet for lists!"))


(defun moin--list-outdent-item (&optional arg)
  "See `moin-command-meta-right' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (user-error "Not implemented yet for lists!"))


(defun moin--list-indent-subtree (&optional arg)
  "See `moin-command-meta-right' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (user-error "Not implemented yet for lists!"))


(defun moin--list-outdent-subtree (&optional arg)
  "See `moin-command-meta-right' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (user-error "Not implemented yet for lists!"))


(defun moin--list-move-subtree-down (&optional arg)
  "See `moin-command-meta-shift-down' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (user-error "Not implemented yet for lists!"))


(defun moin--list-move-subtree-up (&optional arg)
  "See `moin-command-meta-shift-up' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (user-error "Not implemented yet for lists!"))


;; ==================================================
;; Provide package

(provide 'moin-lists)

;;; moin-lists.el ends here
