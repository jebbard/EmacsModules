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
  ;; Usually we like to avoid doing the same thing twice, but here:
  ;; First any list related command in moin-mode.el will call this function
  ;; to determine whether in a list, and then any sub-function called by it
  ;; will again call `moin--list-get-item-info', resulting in one additional,
  ;; but unnecessary call. However, the alternatives would either mean to break
  ;; with the common structure of the rest of the mode (tables and headings), or
  ;; introducing strange global variables. As most modern computers should be
  ;; able to handle this thing, we decided to call `moin--list-get-item-info' twice.
  (if (eq nil (moin--list-get-item-info))
      nil
    t))


;; ==================================================
;; "Private" Functions

(defun moin--list-get-item-info()
  "Retrieves information about the current list item where point is on. Always 
expects to currently be in a list, so any caller must ensure that this is actually
the case. An item info always only refers to the current item and does not care
whether this item is part of the subtree of another item, or it has a subtree itself.

The returned information is: 
(start-pos preamble-end-pos whitespace-before starting-bullet end-pos), where
* start-pos is the start point of the item, i.e. the beginning of the line 
where the starting bullet or number of the list is located on
* preamble-end-pos is the end point of the preamble, i.e. the text including 
whitespace, starting bullet or number and any further whitspace before the actual 
item text starts
* whitespace-before contains any whitespace before the starting bullet or number
* starting-bullet contains the text of the starting bullet or number without any 
whitespace, including a trailing dot for numbers
* end-pos is the end point of the item, i.e. the point after the last character
(excluding last newline) of the item; this IS NOT the point after the last subtree
item of the current item, i.e. if the current item has sub-items, it is the point
at eol before the first subitem."
(let (start-pos
      preamble-end-pos
      whitespace-before-bullet
      whitespace-after-bullet
      starting-bullet
      end-pos
      really-in-list-p
      eob-p
      (list-regex
       "^\\([\t ]+\\)\\([*.]\\|\\([1-9]+\\|[A-Za-z]\\)\\.\\)\\([\t ]*\\)\\([^[:space:]].*?$\\|$\\)"))
  
  (save-excursion
    (beginning-of-line)
    
    (while (and (looking-at "^\\s-") (not (looking-at list-regex)) (not (bobp)))
      (previous-line)
      (beginning-of-line))

    (setq really-in-list-p (looking-at list-regex))
    
    (if really-in-list-p
	(progn
	  (setq start-pos (match-beginning 0))
	  (setq preamble-end-pos (match-beginning 5))

	  (setq whitespace-before-bullet (match-string 1))
	  (setq whitespace-after-bullet (match-string 4))
	  (setq starting-bullet (match-string 2)))))

    (if really-in-list-p
	(progn
	  (save-excursion

	    (setq eob-p nil)
	    (end-of-line)

	    (if (not (eobp))
		(progn
		  (next-line)
		  (beginning-of-line)
		  
		  (while (and (looking-at "^\\s-") (not (looking-at list-regex)) (not eob-p))
		    (end-of-line)
		    (if (eobp)
			(setq eob-p t)
		      (progn
			(next-line)
			(beginning-of-line))))))

	    (if (not eob-p)
		(progn
		  (beginning-of-line)
		  (if (not (bobp))
		      (progn
			(previous-line)
			(end-of-line)))))
	    
	    (setq end-pos (point)))
	  
	  (list start-pos preamble-end-pos whitespace-before-bullet starting-bullet
		whitespace-after-bullet end-pos))
      ;; else return nil
      nil)))


(defun moin--list-insert-item-same-level (&optional arg)
  "See `moin-command-meta-return' for more information.
Expects to actually be in a list as prerequisite. Never call this 
function if point is currently not in a list."
  (let (item-start-pos
	item-preamble-end-pos
	item-whitespace-before
	item-starting-bullet
	item-whitespace-after
	item-info)

    (setq item-info (moin--list-get-item-info))
    
    (if (not item-info)
      (user-error "Not in list currently"))

    (setq item-start-pos (car item-info))
    (setq item-preamble-end-pos (car (cdr item-info)))
    (setq item-whitespace-before (car (cdr (cdr item-info))))
    (setq item-starting-bullet (car (cdr (cdr (cdr item-info)))))
    (setq item-whitespace-after (car (cdr (cdr (cdr (cdr item-info))))))

    (if (>= item-preamble-end-pos (point))
	;; Item text starts after point -> Insert new item in front of current
	(progn
	  (beginning-of-line)
	  (insert item-whitespace-before)
	  (insert item-starting-bullet)
	  (insert item-whitespace-after)
	  (newline)
	  (previous-line)
	  (end-of-line))
      ;; Item text starts before point -> Split item and insert new item after current
      (progn
	(newline)
	(insert item-whitespace-before)
	(insert item-starting-bullet)
	(insert item-whitespace-after)))))


(defun moin--list-insert-item (list-string)
  "Inserts a new item with the given list-string after the current item"
  (unless (or (looking-at "^\\s-*?$") (bolp))
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
