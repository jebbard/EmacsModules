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
;; Constants

(defconst moin-const-bullet-list " * "
  "Starter string for bullet-point list")

(defconst moin-const-numbered-list " 1. "
  "Starter string for numbered list")

;; ==================================================
;; Functions

(defun moin-is-in-list-p ()
  "Is point on a list line? MoinMoin also allows an arbitrary number of 
blank lines or lines with only whitespaces between two list items. Furthermore,
as soon as there is at least one blank or tab at the beginning of a line, it is 
considered to belong to a list, if a previous line contains a list. Only lines 
with a non-whitespace character as first character of the line break the list."
  (save-excursion
    (beginning-of-line)
    ;; This match string usually only covers the first line of an item! The sole case
    ;; where it spans two lines is that after the 
    (setq list-regex
	  "^\\([\t ]+\\)\\([*.]\\|[1-9A-Za-z]\\.\\)[\t ]*\\([^[:space:]].*?$\\|$\\)")
    (while (and (looking-at "^\\s-") (not (looking-at list-regex)) (not (bobp)))
      (previous-line)
      (beginning-of-line))
    (looking-at list-regex)))


;; ==================================================
;; "Private" Functions

(defun moin--list-get-item-info()
  "Retrieves information about the current list item where point is on. Always 
expects to currently be in a list, otherwise it reacts with a user error.

The returned information is: 
(start-pos preamble-end-pos whitespace-before starting-bullet), where
* start-pos is the start position of the item, i.e. the beginning of the line 
where the starting bullet or number of the list is located on
* preamble-end-pos is the end position of the preamble, i.e. the text including 
whitespace, starting bullet or number and any further whitspace before the actual 
item text starts
* whitespace-before contains any whitespace before the starting bullet or number
* starting-bullet contains the text of the starting bullet or number without any 
whitespace, including a trailing dot for numbers"
  (unless (moin-is-in-list-p)
    (user-error "Not in list currently"))

  ;; moin-is-in-list-p stores position of match
  (setq start-pos (match-beginning 0))
  (setq preamble-end-pos (match-beginning 3))

  (setq whitespace-before (match-string 1))
  (setq starting-bullet (match-string 2))

  (list start-pos preamble-end-pos whitespace-before starting-bullet))


(defun moin--list-insert-item-same-level (&optional arg)
  "See `moin-command-meta-return' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (unless (moin-is-in-list-p)
    (user-error "Not in list currently"))

  (setq item-info (moin--list-get-item-info))
  
  (setq current-item-start-pos (car item-info))
  (setq current-item-preamble-end-pos (car (cdr item-info)))
  (setq current-item-whitespace-before (car (cdr (cdr item-info))))
  (setq current-item-starting-bullet (car (cdr (cdr (cdr item-info)))))

  (if (>= current-item-preamble-end-pos (point))
      ;; Item text starts after point -> Insert new item in front of current
      (progn
	(beginning-of-line)
	(insert current-item-whitespace-before)
	(insert current-item-starting-bullet)
	(insert " ")
	(newline)
	(previous-line)
	(end-of-line))
    ;; Item text starts before point -> Split item and insert new item after current
    (progn
      (newline)
      (insert current-item-whitespace-before)
      (insert current-item-starting-bullet)
      (insert " "))))


(defun moin--list-insert-item (list-string)
  "Inserts a new item with the given list-string after the current item"
  (unless (looking-at "^\\s-*?$")
    (end-of-line)
    (newline))
  (insert list-string))


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
