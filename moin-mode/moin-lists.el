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

;;; Code:


;; ==================================================
;; Constants

(defconst moin-const-bullet-list " * "
  "Starter string for bullet-point list.")

(defconst moin-const-numbered-list " 1. "
  "Starter string for numbered list.")

;; ==================================================
;; Functions

(defun moin-is-in-list-p ()
  "Is point on a list line? MoinMoin also allows an arbitrary number
of blank lines or lines with only whitespaces between two list items.
Furthermore, as soon as there is at least one blank or tab at the
beginning of a line, it is considered to belong to a list, if the
previous line belongs to a list. Only lines with a non-whitespace
character as first character of the line do break the list."
  ;; Usually we like to avoid doing the same thing twice, but here it
  ;; is different, intentionally: First any list-related command in
  ;; moin-mode.el will call this function to determine whether in a
  ;; list, and then any sub-function called by it will again call
  ;; `moin--list-get-item-info', resulting in one additional, but
  ;; actually unnecessary call. However, the alternatives would either
  ;; mean to break with the common structure of the rest of the
  ;; moinmode (tables and headings), or introducing strange global
  ;; variables. As we cannot expect any significant performance issues
  ;; by that, we decided to call `moin--list-get-item-info' twice.
  (if (eq nil (moin--list-get-item-info))
      nil
    t))


;; ==================================================
;; "Private" Functions

(defun moin--list-get-item-info()
  "Retrieves information about the current list item where point is
on. Always expects to currently be in a list, so any caller must
ensure that this is actually the case. An item info always only refers
to the current item and does not care whether this item is part of the
subtree of another item, or it has a subtree itself.

The returned information is: 

        (start-point
         end-point
         preamble-end-point
         level
         whitespace-before-bullet
         starting-bullet
         whitespace-after-bullet),

where
 * start-point is the start point of the item, i.e. the beginning of
   the line where the starting bullet or number of the list is located
   on
 * end-point is the end point of the item, i.e. the point after the
   last character (excluding last newline) of the item; this IS NOT
   the point after the last subtree item of the current item, i.e. if
   the current item has sub-items, it is the point at eol before the
   first subitem.
 * preamble-end-point is the end point of the preamble, i.e. the text
   including whitespace, starting bullet or number and any further
   whitspace before the actual item text starts
 * level is an integer specifying the level this item is on, basically
   the number of whitespace characters in front of the starting-bullet
 * whitespace-before-bullet contains any whitespace before the
   starting bullet or number
 * starting-bullet contains the text of the starting bullet or number
   without any whitespace, including a trailing dot for numbers
 * whitespace-after-bullet contains any whitespace after the starting
   bullet or number and before the first text character of the item"
(let (start-point
      end-point
      preamble-end-point
      whitespace-before-bullet
      whitespace-after-bullet
      starting-bullet
      really-in-list-p
      (list-regex
       "^\\([\t ]+\\)\\([*.]\\|\\([1-9]+\\|[A-Za-z]\\)\\.\\)\\([\t ]*\\)\\([^[:space:]].*?$\\|$\\)"))

  ;; First search for the starting bullet of the current item, if any - it can be on any line above
  ;; current point
  (save-excursion
    (beginning-of-line)
    
    (while (and (looking-at "^\\s-") (not (looking-at list-regex)) (not (bobp)))
      (forward-line -1)
      (beginning-of-line))

    (setq really-in-list-p (looking-at list-regex))
    
    (if really-in-list-p
	(progn
	  (setq start-point (match-beginning 0))
	  (setq preamble-end-point (match-beginning 5))

	  (setq whitespace-before-bullet (match-string 1))
	  (setq whitespace-after-bullet (match-string 4))
	  (setq starting-bullet (match-string 2)))))

  ;; Then search for the end point of the current item (NOT the items subtree!) - it can be
  ;; on any line below current point
  (if really-in-list-p
      (progn
	(save-excursion
	  ;; This while loop loops over the next lines as long as line end is not the end of buffer
	  ;; and the line starts with a specific pattern which is not a new item pattern
	  ;; The goal is to determine the correct end-point of the item
	  (while (progn
		   (end-of-line)
		   (setq end-point (point))
		   (if (eobp)
			 nil
		     (progn
		       (forward-line)
		       (beginning-of-line)
		       (and (looking-at "^\\s-") (not (looking-at list-regex))))))))
	
	(list start-point end-point preamble-end-point (length whitespace-before-bullet)
	      whitespace-before-bullet starting-bullet whitespace-after-bullet))
    ;; else return nil
    nil)))


(defun moin--list-insert-item-same-level ()
  "See `moin-command-meta-return' for more information. Expects to
actually be in a list as prerequisite. Never call this function if
point is currently not in a list."
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
    (setq item-preamble-end-pos (car (cdr (cdr item-info))))
    (setq item-whitespace-before (car (cdr (cdr (cdr (cdr item-info))))))
    (setq item-starting-bullet (car (cdr (cdr (cdr (cdr (cdr item-info)))))))
    (setq item-whitespace-after (car (cdr (cdr (cdr (cdr (cdr (cdr item-info))))))))

    (if (>= item-preamble-end-pos (point))
	;; Item text starts after point -> Insert new item in front of current
	(progn
	  (beginning-of-line)
	  (insert item-whitespace-before)
	  (insert item-starting-bullet)
	  (insert item-whitespace-after)
	  (newline)
	  (forward-line -1)
	  (end-of-line))
      ;; Item text starts before point -> Split item and insert new item after current
      (progn
	(newline)
	(insert item-whitespace-before)
	(insert item-starting-bullet)
	(insert item-whitespace-after)))))


(defun moin--list-insert-item (list-string)
  "Inserts a new item with the given LIST-STRING after the current item."
  (unless (or (looking-at "^\\s-*?$") (bolp))
    (newline))
  (insert list-string))


(defun moin--list-do-change-level(change-end-point-func check-func change-func point-shift)
  "Performs the actual change of the list item level, including all
list items from current point until an end point. Uses functions
passed as parameter to customize this function, based on:
 * Dimension 1 - whether its an indentation or an outdentation
 * Dimension 2 - whether it is with or without subtree

Both dimensions are covered by this function by just passing different
helper functions as parameters:
 * CHANGE-END-POINT-FUNC: Function used to determine what the end
   point of the level change is; the level is only changed until (and
   including) the last line before the determined end point. The
   list-item-info of the current item is passed to this function, and
   a point (i.e. an integer position in the buffer) is expected as
   return value.
 * CHECK-FUNC: Function used to verify that level change is possible
   for the current item. The current-item-level is passed to that
   function, no return value is expected. It throws an error if level
   change is not possible.
 * CHANGE-FUNC: The function used to actually change the level of the
   list item, invoked once per line with point at beginning of each
   line. No parameters are passed to this function, no return value is
   expected.
 * POINT-SHIFT: Point is shifted by point-shift (either negative or
   positive integer)."
  (let (current-list-item-info
	current-item-start-point
	current-change-end-point
	current-item-level
	current-point
	current-column
	current-point-at-bol-p
	blanks-considered-so-far)

    (setq current-point (point))
    (setq current-point-at-bol-p (eq current-point (point-at-bol)))
    
    (setq current-list-item-info (moin--list-get-item-info))
    (setq current-item-start-point (car current-list-item-info))
    (setq current-item-level (car (cdr (cdr (cdr current-list-item-info)))))
    
    (setq current-change-end-point (funcall change-end-point-func current-list-item-info))

    (funcall check-func current-list-item-info)
    
    (goto-char current-item-start-point)

    (setq blanks-considered-so-far 0)
    
    (while (and (<= (point) (+ blanks-considered-so-far current-change-end-point)) (not (eobp)))
      (beginning-of-line)
      (funcall change-func)
      
      (setq blanks-considered-so-far (+ 1 blanks-considered-so-far))

      (setq current-column (current-column))
      
      (end-of-line)
      (if (not (eobp))
	  (progn
	    ;; In contrast to next-line, forward-line goes to the start of the next line!
	    ;; So we have to manually move to the previously set column
	    (forward-line)
	    (move-to-column current-column))))

    (if current-point-at-bol-p
	(goto-char current-point)
      (goto-char (+ current-point point-shift)))))


(defun moin--list-check-outdent(current-list-item-info)
  "Based on the CURRENT-LIST-ITEM-INFO provided, this function checks
if outdentation of the current item is possible, and if not, throws a
user-error."
  (let ((current-item-level (car (cdr (cdr (cdr current-list-item-info))))))
    (if (eq current-item-level 1)
	(user-error "Cannot outdent top-level items"))))


(defun moin--list-check-outdent-item-without-subtree(current-list-item-info)
  "Based on the CURRENT-LIST-ITEM-INFO provided, this function checks
if outdentation of the current item without subtree is possible, and
if not, throws a user-error."
  (let ((current-item-level (car (cdr (cdr (cdr current-list-item-info)))))
	(other-list-item-info (moin--list-next-item-info current-list-item-info))
	other-item-level)
    
    (moin--list-check-outdent current-list-item-info)

    (setq other-item-level (car (cdr (cdr (cdr other-list-item-info)))))

    (if (and other-list-item-info (> other-item-level current-item-level))
	(user-error "Cannot outdent an item without its children"))))


(defun moin--list-do-outdent()
  "Performs actual list outdentation of a single line."
  (if (looking-at "[ \t][ \t]")
      (delete-char 1)))


(defun moin--list-outdent-item ()
  "See `moin-command-meta-left' for more information. Expects to
actually be in a list as prerequisite. Never call this function if
point is currently not in a list."
    (moin--list-do-change-level
   '(lambda (current-list-item-info) (car (cdr current-list-item-info)))
   'moin--list-check-outdent-item-without-subtree
   'moin--list-do-outdent
   -1))


(defun moin--list-outdent-subtree ()
  "See `moin-command-meta-right' for more information. Expects to
actually be in a list as prerequisite. Never call this function if
point is currently not in a list."
    (moin--list-do-change-level
   '(lambda (current-list-item-info) (moin--list-get-subtree-end-point current-list-item-info))
   'moin--list-check-outdent
   'moin--list-do-outdent
   -1))


(defun moin--list-check-indent(current-list-item-info)
  "Based on the CURRENT-LIST-ITEM-INFO provided, this function checks
if indentation of the current item is possible, and if not, throws a
user-error."
  (let ((current-item-level (car (cdr (cdr (cdr current-list-item-info)))))
	(other-list-item-info (moin--list-previous-item-info current-list-item-info))
	other-item-level)
  
  (setq other-item-level (car (cdr (cdr (cdr other-list-item-info)))))
  
  (if (or (not other-list-item-info) (< other-item-level current-item-level))
      (user-error "Cannot indent first item of a list"))))


(defun moin--list-do-indent()
  "Performs actual list indentation of a single line."
  (insert " "))


(defun moin--list-indent-item ()
  "See `moin-command-meta-right' for more information. Expects to
actually be in a list as prerequisite. Never call this function if
point is currently not in a list."
    (moin--list-do-change-level
   '(lambda (current-list-item-info) (car (cdr current-list-item-info)))
   'moin--list-check-indent
   'moin--list-do-indent
   +1))


(defun moin--list-indent-subtree ()
  "See `moin-command-meta-right' for more information. Expects to
actually be in a list as prerequisite. Never call this function if
point is currently not in a list."
    (moin--list-do-change-level
   '(lambda (current-list-item-info) (moin--list-get-subtree-end-point current-list-item-info))
   'moin--list-check-indent
   'moin--list-do-indent
   +1))


(defun moin--list-previous-item-info(current-item-info)
  "Determines the list-item-info of the previous list item, if any,
and returns it. If there is no previous item, returns nil. See
`moin--list-get-item-info' for details about the returned data
structure."
  (let (current-start-point)

    (setq current-start-point (car current-item-info))

    (goto-char current-start-point)

    (if (bobp)
	nil
      (progn
	(forward-line -1)
	(moin--list-get-item-info)))))


(defun moin--list-next-item-info(current-item-info)
  "Determines the list-item-info of the next list item, if any, and
returns it. If there is no next item, returns nil. See
`moin--list-get-item-info' for details about the returned data
structure."
  (let (current-end-point)

    (setq current-end-point (car (cdr current-item-info)))

    (goto-char current-end-point)

    (if (eobp)
	nil
      (progn
	(forward-line)
	(moin--list-get-item-info)))))


(defun moin--list-get-sibling-item-info(current-list-item-info move-func)
  "This function returns the list-item-info structure - see
`moin--list-get-item-info' for how it is defined - of a sibling list
item based on the given current-list-item-info, ideally with the same
level, depending on move-func.

There are following cases:
 * move-func = `moin--list-next-item-info': This function searches the
   next list item below the current item, preferably with the same
   level as the current item. The behaviour in the case that there is
   no next item with the same level is as follows: If the current item
   is the very last item in the list without any subitems, its item
   info itself is returned. If the current item subtree is the last
   subtree in the list, the info of its last subtree item is returned.
   If there is a next item with smaller level only, this item's info
   is returned.
 * move-func = `moin--list-previous-item-info': This function searches
   the previous list item above the current item, preferably with the
   same level as the current item. The behaviour in the case that
   there is no previous item with the same level is as follows: If the
   current item is the first item in the list, its item info itself is
   returned. If the current item is not the first item in the list,
   and there is a previous item, but none with the same level, the
   list is actually malformed, but this function simply returns the
   item info of the previous item it can find.

Thus, to e.g. determine if there really is a previous item with the
same level, callers need to check the start point as well as the level
of the list-item-info returned by this function."
  (let (returned-list-item-info
	other-list-item-info
	current-item-level
	other-item-level)

    (setq other-list-item-info current-list-item-info)
    (setq returned-list-item-info current-list-item-info)
    (setq current-item-level (car (cdr (cdr (cdr current-list-item-info)))))
    
    (save-excursion
      (while (progn
	       (setq other-list-item-info (funcall move-func other-list-item-info))
	       (setq other-item-level (car (cdr (cdr (cdr other-list-item-info)))))
	       (if other-list-item-info
		   (setq returned-list-item-info other-list-item-info))
	       
	       (and other-list-item-info (not (eq current-item-level other-item-level))))))

    returned-list-item-info))



(defun moin--list-point-at-beginning-of-next-line-or-eol(current-point)
  "Starting from the current point, returns the point on the start of
the next line, or if there is no next line, the point at end of line."
  (save-excursion
    (goto-char current-point)
    (if (eobp)
	(point-at-eol)
      (progn
	(forward-line)
	(point-at-bol)))))


(defun moin--list-get-subtree-end-point (list-item-info)
  "Determine the end point of the subtree of the given LIST-ITEM-INFO,
i.e. the point where the last child subitem of the given item ends.
Even that is not fully correct - we return the point on the beginning
of the next line after the last child, if there is a next line,
otherwise the point at eol."
  (let (next-list-item-info
	subtree-end-point
	(item-start-point (car list-item-info))
	(item-end-point (car (cdr list-item-info)))
	(item-level (car (cdr (cdr (cdr list-item-info)))))
	next-item-start-point
	next-item-end-point
	next-item-level)

    ;; Search for the end of the current item's subtree
    (setq next-list-item-info
	  (moin--list-get-sibling-item-info list-item-info 'moin--list-next-item-info))
    
    (setq next-item-start-point (car next-list-item-info))
    (setq next-item-end-point (car (cdr next-list-item-info)))
    (setq next-item-level (car (cdr (cdr (cdr next-list-item-info)))))

    ;; Determine the end point of the subtree (after trailing line break, if any, i.e. on
    ;; the next line behind the last subitem's end point)
    (cond
     ;; The current item has no subtree
     ((eq next-item-start-point item-start-point) 
      (setq subtree-end-point
	    (moin--list-point-at-beginning-of-next-line-or-eol item-end-point)))
     ;; The list ends with a subtree item of the current item
     ((> next-item-level item-level) 
      (setq subtree-end-point
	    (moin--list-point-at-beginning-of-next-line-or-eol next-item-end-point)))
     ;; The subtree is followed up by a sibling list item on the
     ;; same or smaller level than the current item's level
     ((<= next-item-level item-level)
      (setq subtree-end-point next-item-start-point)))
    
    subtree-end-point))


(defun moin--list-move-subtree-up ()
  "See `moin-command-meta-shift-up' for more information. Expects to
actually be in a list as prerequisite. Never call this function if
point is currently not in a list."
  (let (current-list-item-info
	current-item-level
	current-item-start-point
	current-subtree-end-point
	previous-list-item-info
	previous-item-level
	previous-item-start-point
	relative-point
	current-item-subtree)

    (setq current-list-item-info (moin--list-get-item-info))
    (setq current-item-start-point (car current-list-item-info))
    (setq current-item-level (car (cdr (cdr (cdr current-list-item-info)))))
    (setq relative-point (- (point) current-item-start-point))

    ;; Search for the end of the current item's subtree
    (setq current-subtree-end-point (moin--list-get-subtree-end-point current-list-item-info))
    
    ;; Search for the previous item on same level, if any
    (setq previous-list-item-info
	  (moin--list-get-sibling-item-info current-list-item-info 'moin--list-previous-item-info))

    (setq previous-item-start-point (car previous-list-item-info))
    (setq previous-item-level (car (cdr (cdr (cdr previous-list-item-info)))))

    ;; There is no previous item on the same level
    (if (or (eq previous-item-start-point current-item-start-point)
	    (not (eq previous-item-level current-item-level)))
	(user-error "Cannot move subtree up, it is already the first item in the subtree with the same level"))
    
    ;; Perform the "item movement"
    (setq current-item-subtree (buffer-substring current-item-start-point current-subtree-end-point))

    (goto-char current-item-start-point)

    (delete-char (- current-subtree-end-point current-item-start-point))

    (goto-char previous-item-start-point)

    (insert current-item-subtree)
    (if (not (eq (point) (point-at-bol)))
	(newline))
    (goto-char (+ previous-item-start-point relative-point))))


(defun moin--list-move-subtree-down ()
  "See `moin-command-meta-shift-down' for more information. Expects to
actually be in a list as prerequisite. Never call this function if
point is currently not in a list.

Implementation idea: Go to the point after current list item's
subtree. If there is no follow-up item on the same level, throw an
error. Otherwise move the next item up, reusing
`moin--list-move-subtree-up'. Then position point such that it is at
the same place relative to the item start."
  (let (list-item-info
  	current-item-level
  	current-item-start-point
  	subtree-end-point
  	next-item-level
  	next-item-start-point
  	relative-point)

    (setq list-item-info (moin--list-get-item-info))
    (setq current-item-start-point (car list-item-info))
    (setq current-item-level (car (cdr (cdr (cdr list-item-info)))))
    (setq relative-point (- (point) current-item-start-point))

    ;; Search for the end of the current item's subtree
    (setq subtree-end-point (moin--list-get-subtree-end-point list-item-info))

    (goto-char subtree-end-point)
    
    (setq list-item-info (moin--list-get-item-info))
    (setq next-item-level (car (cdr (cdr (cdr list-item-info)))))
    (setq next-item-start-point (car list-item-info))

    (if (or (not list-item-info) (eq next-item-start-point current-item-start-point)
	    (not (eq next-item-level current-item-level)))
	(user-error "Cannot move subtree down, it is already the last item in the subtree with the same level"))
    
    (moin--list-move-subtree-up)
    
    (setq list-item-info (moin--list-get-item-info))
    (setq subtree-end-point (moin--list-get-subtree-end-point list-item-info))
    
    (goto-char (+ current-item-start-point (- subtree-end-point (point)) relative-point))))


;; ==================================================
;; Provide package

(provide 'moin-lists)

;;; moin-lists.el ends here
