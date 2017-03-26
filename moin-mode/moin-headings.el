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

;;; Code

;; ==================================================
;; Constants

(defconst moin-const-max-heading-level 5
  "The maximum level of a heading in MoinMoin")


;; ==================================================
;; Functions

(defun moin-is-on-heading-p ()
  "Is point on a header line?"
  (outline-on-heading-p))


;; ==================================================
;; "Private" Functions

(defun moin--heading-determine-content ()
  "Gets the content of the current heading without any prefix or suffix"
  (beginning-of-line)
  (looking-at "=*? \\(.*\\) =")
  (setq heading-content (match-string 1)))


(defun moin--heading-fix-suffix (updated-heading-level)
  "Update and fix the suffix of heading, essentially replaces any combinations of
blanks and '=' at the end of current line with a well-formed heading suffix of the
given level."
  (re-search-forward "[ \t =]*$")
  (replace-match (concat " " (make-string updated-heading-level ?=))))


(defun moin--heading-determine-level ()
  "Determines the level of the current heading, if any. Returns 0 if currently not
on a heading"
  (save-excursion
    (beginning-of-line)
    (looking-at "\\(=+\\) ")
    (setq len (length (match-string 1)))
    len))


(defun moin--heading-determine-section-level()
  "Tries to determine the heading level of the current section where point 
is in. If there is no previous heading, it throws an error."
  (save-excursion
    (outline-back-to-heading t)
    
    (if (not (moin-is-on-heading-p))
	(user-error "Point is currently not in a section with a heading"))

    (moin--heading-determine-level)))


(defun moin--determine-heading-folding-state ()
  "Determins the state of folding of the current heading. This function assumes
that the point is currently on a heading line. 
The states are:
 * FOLDED: Hides the entire subtree and content of the current heading
 * CHILDREN: Shows the content of the current heading and all direct child 
headings of the next lower level below the current heading. The child heading
subtrees remain hidden.
 * SUBTREE: The entire content and subtree below the current heading is 
shown entirely, no folding"
  ;; Current headline is FOLDED
  (if (invisible-p (point-at-eol))
      "FOLDED"
    ;; else
    (save-excursion

      (setq current-heading-level (moin--heading-determine-level))

      ;; Check whether at least one direct child heading has an invisible body
      (setq is-child-heading t)
      (setq has-folded-children nil)
      
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
	"SUBTREE"))))


(defun moin--heading-move-subtree-up-or-down (&optional arg)
  "Move the current subtree up or down past ARG headlines of the same level.
This is a bugfix version of outline-move-subtree-down copied from
Emacs 25.1, slightly adapted. See GNU Emacs bug#19102. Only uses the 
bugfix code if emacs major version is < 25."
  (interactive "p")
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
    (outline-move-subtree-dowh arg)))


(defun moin--heading-execute-action-on-subtree (action &optional initial-level curr-level)
  "Executes a given action on the whole subtree of the current heading, including the current
heading itself. The function sets point to the start of each of the headings belonging to the
subtree of the current heading. Must be called only if point is currently on a heading."
  (if (not (moin-is-on-heading-p))
      (user-error "Only working on a heading"))
  (save-excursion
    (beginning-of-line)
    ;; Get level of current heading
    (if (not curr-level)
	(setq current-heading-level (moin--heading-determine-level))
      (setq current-heading-level curr-level))

    (if (not initial-level)
	(setq initial-level current-heading-level))
    
    (funcall action current-heading-level)

    ;; Set point to next heading (no matter if visible or not)
    (outline-next-heading)
    
    (if (moin-is-on-heading-p)
	(progn 
	  (setq next-heading-level (moin--heading-determine-level)))
      ;; else
      (setq next-heading-level 0))

    ;; Real child found
    (if (> next-heading-level initial-level)
	(progn
	  (moin--heading-execute-action-on-subtree action initial-level next-heading-level)))))


(defun moin--heading-do-demote(current-level)
  "Performs actual demotion of the current heading"
  (if (= current-level moin-const-max-heading-level)
      (user-error "Cannot demote heading '%s', because it is already on maximum level %s"
		  (moin--heading-determine-content) moin-const-max-heading-level)
    ;; else
    (outline-demote nil)
    (moin--heading-fix-suffix (+ current-level 1))))


(defun moin--heading-do-promote(current-level)
  "Performs actual promotion of the current heading"
  (if (= current-level 1)
      (user-error "Cannot promote heading '%s', because it is already on minimum level 1"
		  (moin--heading-determine-content))
    ;; else
    (outline-promote nil)
    (moin--heading-fix-suffix (- current-level 1))))


(defun moin--heading-change-level (change-func including-subtree)
  "Promotes or demotes the current heading (depending on the change-func provided), 
either with or without subtree. This function was created to also take care of the 
special characteristics of MoinMoin headings: They are enclosed by '=' signs. 
Unfortunately, outline-mode does not support this, i.e. it only demotes the 
prefix of the heading, leaving the suffix unchanged. Thus, moin-mode itself needs 
to take care of also demoting or promoting the rest of the heading."
  (save-excursion
    (if mark-active
	(user-error "Command not supported if mark is active"))
    (if including-subtree
	(moin--heading-execute-action-on-subtree change-func)
      (setq current-heading-level (moin--heading-determine-level))
      (funcall change-func current-heading-level))))


(defun moin--heading-outline-cycle (&optional arg)
  "Implements outline cycle, see `' for more details."
  (interactive "p")
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
	       (message "FOLDED"))))))


(defun moin--heading-create (level &optional text)
  "Creates a new heading at the current point and positions point
after the heading prefix"
  (beginning-of-line)
  (insert (make-string level ?=))
  (insert "  ")
  (insert (make-string level ?=))
  (newline)
  (previous-line)
  (move-to-column (+ level 1))
  (if text
      (insert text)))


(defun moin--heading-insert (&optional arg)
  "Inserts a new heading before or behind the current one, see 
`moin-command-meta-return' for details."
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
		(setq new-heading-text (buffer-substring (point) (- (point-at-eol) current-heading-level 1)))
		(delete-region (point) (- (point-at-eol) current-heading-level 1))))
	    (end-of-line)
	    (newline)
	    (moin--heading-create current-heading-level new-heading-text))))
    (progn
      (setq current-heading-level (moin--heading-determine-section-level))
      (newline)
      (moin--heading-create current-heading-level))))


(defun moin--heading-insert-respect-content (&optional arg)
  "See `moin-command-insert-heading-respect-content' for details."
  (setq current-heading-level (moin--heading-determine-section-level))

  ;; Check whether at least one direct child heading has an invisible body
  (setq is-child-heading t)
  
  (while is-child-heading
    (progn
      ;; Set point to next heading (no matter if visible or not)
      (outline-next-heading)
      
      (if (moin-is-on-heading-p)
	  (setq next-heading-level (moin--heading-determine-level))
	;; else
	(setq next-heading-level 0))

      ;; Current heading has children
      (if (<= next-heading-level current-heading-level)
	  (setq is-child-heading nil))))

  (if (eq next-heading-level 0)
      (end-of-buffer))

  (moin--heading-create current-heading-level))


;; ==================================================
;; Provide package

(provide 'moin-headings)

;;; moin-headings.el ends here
