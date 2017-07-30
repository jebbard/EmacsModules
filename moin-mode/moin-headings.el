;;; moin-headings.el --- Heading support for moin mode

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

;; Heading support for moin mode

;;; Code:

(require 'outline)

;; ==================================================
;; Constants

(defconst moin-const-max-heading-level 5
  "The maximum level of a heading in MoinMoin.")


;; ==================================================
;; Functions

(defun moin-is-on-heading-p ()
  "Is point on a header line?"
  (save-excursion
    (beginning-of-line)
    (looking-at "=\\{1,5\\} ")))


;; ==================================================
;; "Private" Functions

(defun moin--heading-determine-content ()
  "Gets the content of the current heading without any prefix or
suffix."
  (save-excursion
    (beginning-of-line)
    (looking-at "=*? \\(.*\\) .*?\\(=\\|$\\)")
    (match-string 1)))


(defun moin--heading-fix (updated-heading-level)
  "Update and fix the prefix and suffix of a heading, essentially
replaces any combinations of blanks and '=' at the end or beginning of
current line with a well-formed heading suffix of the given
UPDATED-HEADING-LEVEL."
  (let
      ((heading-pre-suf (make-string updated-heading-level ?=)))
    (beginning-of-line)
    ;; Fix start of heading
    (if (re-search-forward "^[ \t =]*")
	(replace-match (concat heading-pre-suf " ")))
    ;; Fix end of heading
    (if (re-search-forward "[ \t =]*$")
	(replace-match (concat " " heading-pre-suf)))))


(defun moin--heading-determine-level ()
  "Determines the level of the current heading, if any. Returns 0 if
currently not on a heading"
  (let (len)
    (save-excursion
      (beginning-of-line)
      (looking-at "\\(=+\\) ")
      (setq len (length (match-string 1)))
      len)))


(defun moin--heading-determine-section-level()
  "Tries to determine the heading level of the current section where
point is in. If there is no previous heading, it throws an error."
  (let (section-level)
    (save-excursion
      (setq section-level (condition-case nil
			      (progn
				(outline-back-to-heading t)
				(moin--heading-determine-level))
			    (error 0))))))


(defun moin--determine-heading-folding-state ()
  "Determins the state of folding of the current heading. This
function assumes that the point is currently on a heading line. The
states are:
 * FOLDED: Hides the entire subtree and content of the current heading
 * CHILDREN: Shows the content of the current heading and all direct
   child headings of the next lower level below the current heading.
   The child heading subtrees remain hidden.
 * SUBTREE: The entire content and subtree below the current heading
   is shown entirely, no folding"
  (let (current-heading-level
	next-heading-level
	(is-child-heading t)
	(has-folded-children nil))

    ;; Current headline is FOLDED
    (if (invisible-p (point-at-eol))
	"FOLDED"
      ;; else
      (save-excursion

	(setq current-heading-level (moin--heading-determine-level))

	;; Check whether at least one direct child heading has an invisible body
	(while (and is-child-heading (not has-folded-children))
	  (progn
	    ;; Set point to next heading (no matter if visible or not)
	    (outline-next-heading)
	    
	    (if (moin-is-on-heading-p)
		(progn 
		  (setq next-heading-level (moin--heading-determine-level)))
	      ;; else
	      (setq next-heading-level 0))

	    ;; Current heading has children
	    (if (eq (+ current-heading-level 1) next-heading-level)
		(if (invisible-p (point-at-eol))
		    (setq has-folded-children t))
	      (setq is-child-heading nil))))

	(if has-folded-children
	    (progn "CHILDREN")
	  "SUBTREE")))))


(defun moin--heading-move-subtree-up-or-down (arg)
  "Move the current subtree up or down past ARG headlines of the same level.
This is a bugfix version of `outline-move-subtree-down' copied from
Emacs 25.1, slightly adapted. See GNU Emacs bug#19102. Only uses the 
bugfix code if Emacs major version is < 25."
  (interactive "p")
  (let ((current-column (current-column)))
    
    (if (< emacs-major-version 25)
	(progn 
	  (outline-back-to-heading)
	  (let* ((movfunc (if (> arg 0) 'outline-get-next-sibling
			    'outline-get-last-sibling))
		 ;; Find the end of the subtree to be moved as well as the point to
		 ;; move it to, adding a newline if necessary, to ensure these points
		 ;; are at bol on the line below the subtree.
		 (end-point-func (lambda ()
				   (outline-end-of-subtree)
				   (if (eq (char-after) ?\n) (forward-char 1)
				     (if (and (eobp) (not (bolp))) (insert "\n")))
				   (point)))
		 (beg (point))
		 (folded (save-match-data
			   (outline-end-of-heading)
			   (outline-invisible-p)))
		 (end (save-match-data
			(funcall end-point-func)))
		 (ins-point (make-marker))
		 (cnt (abs arg)))
	    ;; Find insertion point, with error handling.
	    (goto-char beg)
	    (while (> cnt 0)
	      (or (funcall movfunc)
		  (progn (goto-char beg)
			 (user-error "Cannot move past superior level")))
	      (setq cnt (1- cnt)))
	    (if (> arg 0)
		;; Moving forward - still need to move over subtree.
		(funcall end-point-func))
	    (move-marker ins-point (point))
	    (insert (delete-and-extract-region beg end))
	    (goto-char ins-point)
	    (if folded (hide-subtree))
	    (move-marker ins-point nil)))
      ;; else if emacs major version >= 25
      (outline-move-subtree-down arg))

    (move-to-column current-column)))


(defun moin--heading-execute-action-on-subtree (action &optional parent-level curr-level)
  "Executes a given ACTION on the whole subtree of the current parent
heading (with PARENT-LEVEL), including the current parent heading
itself. The parameter CURR-LEVEL tracks the current level of the
subtree to ensure the recursive call can be terminated. The
PARENT-LEVEL is always keeping the level of the heading where this
function was first called. When initially calling this method, these
two parameters can be nil, in which case they are explicitly
determined within this function. The function sets point to the start
of each of the headings belonging to the subtree of the current
heading. Must be called only if point is currently on a heading."
  (let (current-heading-level
	next-heading-level
	current-point)
    
    (if (not (moin-is-on-heading-p))
	(user-error "Only working on a heading"))
    
    (save-excursion
      (beginning-of-line)
      ;; Get level of current heading
      (if (not curr-level)
	  (setq current-heading-level (moin--heading-determine-level))
	(setq current-heading-level curr-level))

      (if (not parent-level)
	  (setq parent-level current-heading-level))
      
      (funcall action current-heading-level)

      ;; Set point to next heading (no matter if visible or not)
      (end-of-line)
      (setq current-point (point))
      (outline-next-heading)
      
      ;; In a special case (heading at end of buffer) we could be still on the same heading,
      ;; we exclude this point here
      (if (not (eq current-point (point)))
	  (progn
	    (if (moin-is-on-heading-p)
		(progn 
		  (setq next-heading-level (moin--heading-determine-level)))
	      ;; else
	      (setq next-heading-level 0))

	    ;; Real child found
	    (if (> next-heading-level parent-level)
		(progn
		  (moin--heading-execute-action-on-subtree action parent-level next-heading-level))))))))


(defun moin--heading-do-demote(current-level)
  "Performs actual demotion of the current heading which has
CURRENT-LEVEL."
  (if (= current-level moin-const-max-heading-level)
      (user-error "Cannot demote heading '%s', because it is already on maximum level %s"
		  (moin--heading-determine-content) moin-const-max-heading-level)
    ;; else
    (outline-demote nil)
    (moin--heading-fix (+ current-level 1))))


(defun moin--heading-do-promote(current-level)
  "Performs actual promotion of the current heading which has
CURRENT-LEVEL"
  (if (= current-level 1)
      (user-error "Cannot promote heading '%s', because it is already on minimum level 1"
		  (moin--heading-determine-content))
    ;; else
    (outline-promote nil)
    (moin--heading-fix (- current-level 1))))


(defun moin--heading-change-level (change-func including-subtree column-change)
  "Promotes or demotes the current heading (depending on the
CHANGE-FUNC provided), either with or without subtree, depending on
the value of INCLUDING-SUBTREE. Callers indicated with the integer
passes as COLUMN-CHANGE where to move (relative to the current column)
after executing this function. This function was created to also take
care of the special characteristics of MoinMoin headings: They are
enclosed by '=' signs. Unfortunately, `outline-mode' does not support
this, i.e. it only demotes the prefix of the heading, leaving the
suffix unchanged. Thus, moin-mode itself needs to take care of also
demoting or promoting the rest of the heading."
  (let (current-heading-level current-column)

    (save-excursion
      (if mark-active
	  (user-error "Command not supported if mark is active"))
      (setq current-heading-level (moin--heading-determine-level))
      (setq current-column (current-column))
      
      (if including-subtree
	  (moin--heading-execute-action-on-subtree change-func)
	(funcall change-func current-heading-level)))

      ;; Ensure point is at the right position after the command
      (if (> current-column (- (point-at-eol) (point-at-bol)))
	  (end-of-line)
	(if (>= (+ current-column column-change) 0)
	    (move-to-column (+ current-column column-change))
	  (beginning-of-line)))))


(defun moin--heading-outline-cycle ()
  "Implements outline cycle, see `' for more details."
  (let (folding-state)
    (if (moin-is-on-heading-p)
	(progn
	  (setq folding-state (moin--determine-heading-folding-state))
	  
	  (cond ((string= "FOLDED" folding-state)
		 (show-entry)
		 (show-children)
		 (message "CHILDREN"))
		((string= "CHILDREN" folding-state)
		 (show-subtree)
		 (message "SUBTREE"))
		((string= "SUBTREE" folding-state)
		 (hide-subtree)
		 (message "FOLDED")))))))


(defun moin--heading-create (level &optional text)
  "Creates a new heading with the given LEVEL with the given TEXT, at
the current point and moves point after the heading prefix."
  (beginning-of-line)
  (insert (make-string level ?=))
  (insert "  ")
  (insert (make-string level ?=))
  (newline)
  (forward-line -1)
  (move-to-column (+ level 1))
  (if text
      (insert text)))


(defun moin--heading-insert ()
  "Inserts a new heading before or behind the current one, see
`moin-command-meta-return' for details."
  (let (current-heading-level new-heading-text)
    
    (if (moin-is-on-heading-p)
	(progn
	  (setq current-heading-level (moin--heading-determine-level))
	  
	  ;; Insert new heading before current one
	  (if (eq (current-column) 0)
	      (moin--heading-create current-heading-level)
	    ;; Insert new heading with no content after current one, if
	    ;; point is within heading delimiters (at beginning or end)
	    (progn
	      (if (or (<= (current-column) (+ current-heading-level 1))
		      (<= (- (point-at-eol) (point)) (+ current-heading-level 1)))
		  (setq new-heading-text "")
		;; Otherwise just split current heading text to new heading
		(progn
		  (setq new-heading-text
			(buffer-substring-no-properties (point)
							(- (point-at-eol) current-heading-level 1)))
		  (delete-region (point) (- (point-at-eol) current-heading-level 1))))
	      (end-of-line)
	      (newline)
	      (moin--heading-create current-heading-level new-heading-text))))
      (progn
	(setq current-heading-level (moin--heading-determine-section-level))

	(if (eq current-heading-level 0)
	    (setq current-heading-level 1))

	(if (not (bobp))
	    (newline))

	(moin--heading-create current-heading-level)))))


(defun moin--heading-insert-respect-content ()
  "See `moin-command-insert-heading-respect-content' for details."
  (let (current-heading-level
	next-heading-level
	might-have-further-child-headings-p
	initial-point
	current-point)

    (setq current-heading-level (moin--heading-determine-section-level))

    ;; When there is no heading before point: search for the next heading
    ;; or the end of the current buffer
    (if (eq current-heading-level 0)
	(progn
	  (outline-next-heading)
	  (if (moin-is-on-heading-p)
	      (setq current-heading-level (moin--heading-determine-level))
	    (progn
	      (setq current-heading-level 1)
	      (goto-char (point-max))
	      (if (not (looking-at "^$"))
		  (newline))))
	  (moin--heading-create current-heading-level))
      (progn

	(if (and (moin-is-on-heading-p) (bolp))
	    (moin--heading-create current-heading-level)
	  (progn
	    (setq might-have-further-child-headings-p t)
	    (end-of-line)

	    (setq initial-point (point))
	    (setq current-point nil)

	    ;; If point remains where it is, there is actually no next heading
	    ;; and we need to terminate the loop
	    (while might-have-further-child-headings-p
	      (setq current-point (point))
	      
	      (outline-next-heading)

	      (if (eq current-point (point))
		  (progn
		    (setq next-heading-level (moin--heading-determine-level))
		    (setq might-have-further-child-headings-p nil))
		(progn
		  (if (moin-is-on-heading-p)
		      (setq next-heading-level (moin--heading-determine-level))
		    (setq next-heading-level 0))
		  (setq might-have-further-child-headings-p (> next-heading-level current-heading-level)))))

	    (end-of-line)

	    ;; After the while loop, there are four cases that could be distinguished:
	    ;; (1) Point has not moved at all --> Heading has no children nor siblings, go to eob
	    ;; (2) Point is on a child heading --> go to eob
	    ;; (3) Pathetic case that point is not on a heading --> go to eob
	    ;; (4) Nothing of the above, which means point is on a sibling heading
	    (if (or (and (moin-is-on-heading-p) (> (moin--heading-determine-level) current-heading-level))
		    (not (moin-is-on-heading-p))
		    (and (moin-is-on-heading-p) (eq initial-point (point))))
		(progn
		  (goto-char (point-max))
		  (if (not (looking-at "^$"))
		      (newline))))
	    
	    (moin--heading-create current-heading-level)))))))


;; ==================================================
;; Provide package

(provide 'moin-headings)

;;; moin-headings.el ends here
