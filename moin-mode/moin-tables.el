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

;;; Code:


;; Required for string trimming functions (since Emacs 24.4)
(require 'subr-x)

;; ==================================================
;; Constants

(defconst moin-const-table-default-size "5x2"
  "The default size of a new table in moin mode.")

(defconst moin-const-table-delimiter "||"
  "The MoinMoin table delimiter.")

(defconst moin-const-quoted-table-delimiter
  (regexp-quote moin-const-table-delimiter)
  "The MoinMoin table delimiter in a regexp quoted form.")

(defconst moin-const-empty-field-with-left-delimiter
  (concat moin-const-table-delimiter "  ")
  "Empty field content (two blanks) with the left table delimiter.")

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


(defun moin--table-goto-previous-row ()
  "Tries to move to the beginning of the previous table row, if any.
Returns t if there is a previous line that is a table row, nil
otherwise. If there is a previous line, it remains there, even if it
might not be a table row."
  (beginning-of-line)
  (if (bobp)
      nil
    (progn
      (forward-line -1)
      (moin-is-in-table-p))))


(defun moin--table-goto-next-row ()
  "Tries to move to the end of the next table row, if any. Returns t
if there is a next line that is a table row, nil otherwise. If there
is a next line, it remains there, even if it might not be a table
row."
  (end-of-line)
  (if (eobp)
      nil
    (progn
      (forward-line)
      (moin-is-in-table-p))))


(defun moin--table-next-row (mode)
  "See `moin-command-table-next-row' for more information. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table. The parameter MODE is a string and
can have the values:
* BASIC: Just go to the next row, create one, if necessary,
  realign original and target field
* COPY: Copy down content of the current field to the next row, create
  one, if necessary, override content already present in the target
  field if necessary, realign original and target field
* SPLIT: Split content of the current field to the next row, create
  one if necessary, prepend content already present in the target
  field with the text split from the previous field, if necessary,
  realign original and target field."
  (let
      (initial-point
       current-row-column-details
       current-table-column
       current-field-info
       current-field-start-point
       current-field-end-point
       current-field-text
       current-field-text-override
       next-row-column-details
       next-field-info
       next-field-start-point
       next-field-text
       next-field-text-override)

    (if (use-region-p)
	(deactivate-mark))

    (setq initial-point (point))

    (if (or (eolp) (bolp))
  	(if (string= mode "BASIC")
  	    (newline)
  	  (user-error "Point must be within a table field for this command"))
      (progn
	;; Determine details of current row and current field
  	(setq current-row-column-details (moin--table-determine-column-details))
  	(setq current-table-column (car current-row-column-details))
  	(setq current-field-info (nth current-table-column current-row-column-details))
	(setq current-field-start-point (car current-field-info))
  	(setq current-field-end-point (car (cdr current-field-info)))
  	(setq current-field-text (car (cdr (cdr current-field-info))))

	;; Determine new text (if any) of current and next field
	(setq current-field-text-override current-field-text)
	(setq next-field-text-override next-field-text)
	
	(cond ((string= mode "SPLIT")
	       (if (< initial-point current-field-start-point)
		   (setq initial-point current-field-start-point)
		 (if (> initial-point current-field-end-point)
		     (setq initial-point current-field-end-point)))
	       (setq current-field-text-override
		     (buffer-substring-no-properties current-field-start-point initial-point))
	       (setq next-field-text-override
		     (string-trim (buffer-substring-no-properties initial-point current-field-end-point))))
	      ((string= mode "COPY")
	       (setq next-field-text-override current-field-text)))

	;; Fix current field (must be done before taking details of next field as it might move point)
	(moin--table-fix-field current-field-info current-field-text-override)

        ;; Go to next table row, if there is none, create it
  	(end-of-line)

        (if (eobp)
  	    (newline)
  	  (forward-line))

  	(if (not (moin-is-in-table-p))
  	    (progn
  	      (forward-line -1)
  	      (moin--table-insert-row nil)))

	;; Determine details of next row and next field
  	(setq next-row-column-details (moin--table-determine-column-details))
	
	(if (< (length next-row-column-details) (+ current-table-column 1))
	    (user-error "Malformed table, less columns than in row before, please fix manually!"))
	  
	(setq next-field-info (nth current-table-column next-row-column-details))
	(setq next-field-start-point (car next-field-info))
	(setq next-field-text (car (cdr (cdr next-field-info))))

	;; Specifically for SPLIT: After having determined the text of the next field previously,
	;; we have to prepend it with the text split from current field
	(cond ((string= mode "SPLIT")
	       (setq next-field-text-override
		     (concat next-field-text-override (string-trim next-field-text)))))

	(moin--table-fix-field next-field-info next-field-text-override)

	;; Goto final position
	(goto-char (+ next-field-start-point 1))))))


(defun moin--table-previous-field ()
  "See `moin-command-table-previous-field' for more information.
Expects to actually be in a table as prerequisite. Never call this
function if point is currently not in a table."
    (let
      (column-details
       previous-column-details
       current-table-column
       current-column-info
       previous-column-info
       previous-start-point
       current-column
       end-delimiter-start-column)

    (setq column-details (moin--table-determine-column-details))
    (setq current-table-column (car column-details))
    (setq current-column-info (nth current-table-column column-details))
    (setq current-column (current-column))
    (setq end-delimiter-start-column (- (point-at-eol) (point-at-bol) 2))

    (moin--table-fix-field current-column-info)

    ;; If we are behind the last field, we have to move there
    (if (> current-column end-delimiter-start-column)
	(setq previous-column-info current-column-info)
      ;; If we are in fields 2 to N, we have to move to the previous
      ;; column in the current row
      (progn
	(if (> current-table-column 1)
	    (progn
	      ;; No update of column details necessary here, as we just fixed the next field
	      (setq previous-column-details column-details)
	      (setq previous-column-info (nth (- current-table-column 1) previous-column-details)))
	  ;; If we are in field 1, we have to move to the last
	  ;; column in the previous row, if any
	  (if (eq current-table-column 1)
	      (progn
		(if (not (moin--table-goto-previous-row))
		    (user-error "No previous field in this table"))

		(setq previous-column-details (moin--table-determine-column-details))
		(setq previous-column-info (nth
					    (- (length previous-column-details) 1) previous-column-details)))))

	(moin--table-fix-field previous-column-info)))
    
    (setq previous-start-point (car previous-column-info))

    (goto-char (+ previous-start-point 1))))


(defun moin--table-next-field ()
  "See `moin-command-tab' for more information. Expects to actually be
in a table as prerequisite. Never call this function if point is
currently not in a table."
  (let
      (column-details
       next-column-details
       current-table-column
       current-column-info
       next-column-info
       next-start-point
       current-column)

    (setq column-details (moin--table-determine-column-details))
    (setq current-table-column (car column-details))
    (setq current-column-info (nth current-table-column column-details))
    (setq current-column (current-column))

    (moin--table-fix-field current-column-info)

    ;; If we are before the first field, we have to move there
    (if (< current-column 2)
	(setq next-column-info current-column-info)
      ;; If we are in fields 1 to N-1, we have to move to the next
      ;; column in the current row
      (progn
	(if (< current-table-column (length (cdr column-details)))
	    (progn
	      ;; Update column details, as the fix might have moved the next column
	      (setq next-column-details (moin--table-determine-column-details))
	      (setq next-column-info (nth (+ current-table-column 1) next-column-details)))
	  ;; If we are in field N, we have to move to the first
	  ;; column in the next row, if any
	  (if (eq current-table-column (length (cdr column-details)))
	      (progn
		(end-of-line)
		
		(if (eobp)
		    (newline)
		  (forward-line))

		(if (not (moin-is-in-table-p))
		    (progn
		      (forward-line -1)
		      (moin--table-insert-row nil)))

		(setq next-column-details (moin--table-determine-column-details))
		(setq next-column-info (car (cdr next-column-details))))))

	(moin--table-fix-field next-column-info)))
    
    (setq next-start-point (car next-column-info))

    (goto-char (+ next-start-point 1))))


(defun moin--table-fix-field (field-info &optional new-field-text)
  "Fixes the content of a field by ensuring it starts and ends with a
single blank. Expects a FIELD-INFO list with start-point of field as
first element, end-point of field as second and field-text as third
element. If a NEW-FIELD-TEXT is given, the old field-text is replaced
by the new-field-text, ensuring single blanks at start and end as
described. After this function, point will be at the end of the field
text, i.e. after the padding blank."
  (let ((start-point (car field-info))
    (end-point (car (cdr field-info)))
    (field-text (car (cdr (cdr field-info)))))

    (if (not new-field-text)
	(setq new-field-text field-text))

    (setq new-field-text (concat " " (string-trim new-field-text) " "))
    (goto-char start-point)

    (if (re-search-forward (regexp-quote field-text) (point-at-eol) t)
	(replace-match new-field-text nil t))))


(defun moin--table-do-swap (leftmost-column-info rightmost-column-info)
  "Performs actual table swapping by replacing strings belonging to
different table columns in the current row. Specifically, it swaps the
column identified by LEFTMOST-COLUMN-INFO with the column identified
by RIGHTMOST-COLUMN-INFO."
  (let ((leftmost-text (car (cdr (cdr leftmost-column-info))))
	(leftmost-start-point (car leftmost-column-info))
	(leftmost-end-point (car (cdr leftmost-column-info)))
	(rightmost-text (car (cdr (cdr rightmost-column-info))))
	(rightmost-start-point (car rightmost-column-info))
	(rightmost-end-point (car (cdr rightmost-column-info)))
	text-between-columns
	string-to-replace
	replacement-string)
  
  (setq text-between-columns
	(buffer-substring-no-properties leftmost-end-point rightmost-start-point))

  (setq string-to-replace
	(buffer-substring-no-properties leftmost-start-point rightmost-end-point))

  (setq replacement-string
	(concat rightmost-text text-between-columns leftmost-text))
  
  (goto-char leftmost-start-point)
  
  (if (search-forward string-to-replace rightmost-end-point t)
      (replace-match replacement-string t t)
    (user-error "Illegal state - did not find buffer string to replace, terminating function"))))


(defun moin--table-swap-columns(current-row-column-details current-table-column swap-left)
  "Swaps the CURRENT-TABLE-COLUMN of a moin table with its previous
 column - if SWAP-LEFT is non-nil - or next column - if SWAP-LEFT is
 nil. If there is no such column, throws an error. The details of the
 current row must be determined before and passed in the parameter
 CURRENT-ROW-COLUMN-DETAILS."
  (let (current-column-info
	current-column-text
	current-column-start-point
	current-column-end-point
	other-column-info
	other-column-text
	other-column-start-point
	other-column-end-point
	text-between-columns
	string-to-replace
	replacement-string
	column-count)

    (setq column-count (- (length current-row-column-details) 1))
    
    (if (or (and swap-left (eq current-table-column 1))
	    (and (not swap-left) (eq current-table-column column-count)))
      (user-error "Cannot move column further"))
  
  (setq current-column-info (nth current-table-column current-row-column-details))
  
  (if swap-left
      (progn
	(setq other-column-info (nth (- current-table-column 1) current-row-column-details))
	(moin--table-do-swap other-column-info current-column-info)
	(setq other-column-start-point (car other-column-info))
	(goto-char other-column-start-point))
    (progn
      (setq other-column-info (nth (+ current-table-column 1) current-row-column-details))
      (moin--table-do-swap current-column-info other-column-info)
      (setq current-column-start-point (car current-column-info))
      (setq other-column-text (car (cdr (cdr other-column-info))))
      (goto-char
       (+ current-column-start-point (length other-column-text) (length moin-const-table-delimiter)))))))


(defun moin--table-execute-function-per-row (function &optional args)
  "Executes a FUNCTION for each row of the current table. This
function assumes that it is already in a table. It gets the
current-row-column-details, and executes the given function first for
the current row, then for all previous rows (if any), and finally for
all upcoming table rows (if any). The function must take the
current-row-column-details as first and the current-table-column as
second argument. It can take arbitrary additional ARGS that can be
passed to this function."
  (let (current-row-column-details current-table-column	column-count)

    (setq column-count (- (length current-row-column-details) 1))

    (setq current-row-column-details (moin--table-determine-column-details))
    (setq current-table-column (car current-row-column-details))

    (moin--table-check-row current-row-column-details current-table-column)

    ;; Perform function in current table row
    (funcall function current-row-column-details current-table-column args)
    
    ;; Perform function in previous table rows (if any)
    (save-excursion
      (while (moin--table-goto-previous-row)
	(setq current-row-column-details (moin--table-determine-column-details))

	(moin--table-check-row current-row-column-details current-table-column)

	(funcall function current-row-column-details current-table-column args)))
    
    ;; Perform function in next table rows (if any)
    (save-excursion
      (while (moin--table-goto-next-row)
	(setq current-row-column-details (moin--table-determine-column-details))

	(moin--table-check-row current-row-column-details current-table-column)

	(funcall function current-row-column-details current-table-column args)))))


(defun moin--table-check-row (current-row-column-details current-table-column)
  "Checks the current table row identified by
CURRENT-ROW-COLUMN-DETAILS for having at least CURRENT-TABLE-COLUMN
columns. If that is not the case, it throws a corresponding error."
  (let (column-count)
    (setq column-count (- (length current-row-column-details) 1))
    
    (if (eq (+ 1 column-count) current-table-column)
	(user-error "Malformed table, not enough columns in current row"))))


(defun moin--table-do-remove-column (current-row-column-details current-table-column &optional arg)
  "Based on the information contained in CURRENT-ROW-COLUMN-DETAILS,
this function performs actual removal of the CURRENT-TABLE-COLUMN, .
The last argument ARG is just a dummy never used, it is just needed
such that `moin--table-execute-function-per-row' can be used to
trigger this function."
  (let (current-column-info
	current-column-start-point
	current-column-end-point
	previous-column-info
	previous-column-start-point
	column-count)

    (setq column-count (- (length current-row-column-details) 1))
    
    (setq current-column-info (nth current-table-column current-row-column-details))
    
    (setq current-column-start-point (car current-column-info))
    (setq current-column-end-point (car (cdr current-column-info)))

    (goto-char current-column-start-point)

    (delete-char
     (- (+ current-column-end-point (length moin-const-table-delimiter)) current-column-start-point) nil)

    ;; Special case that the current table has just the single column to remove
    (if (eq 1 column-count)
	(progn
	  (beginning-of-line)
	  (delete-char (length moin-const-table-delimiter) nil))
      ;; Special case: Current column is the last (but not the only) column in the table,
      ;; Goto the beginning of the previous table column in that special case
      (if (eq current-table-column column-count)
	(progn
	  (setq previous-column-info (nth (- current-table-column 1) current-row-column-details))
	  (setq previous-column-start-point (car previous-column-info))
	  (goto-char previous-column-start-point))))))


(defun moin--table-do-insert-column (current-row-column-details current-table-column &optional arg)
  "Based on the information contained in CURRENT-ROW-COLUMN-DETAILS,
performs actual insertion of a new column in front of the
CURRENT-TABLE-COLUMN. The last argument ARG is just a dummy never
used, it is just needed such that
`moin--table-execute-function-per-row' can be used to trigger this
function."
  (let (current-column-info
	current-column-start-point)

    (setq current-column-info (nth current-table-column current-row-column-details))
    
    (setq current-column-start-point (car current-column-info))

    (goto-char current-column-start-point)

    (backward-char (length moin-const-table-delimiter))

    (insert moin-const-empty-field-with-left-delimiter)
    (backward-char)))


(defun moin--table-move-column-right ()
  "See `moin-command-meta-right' for more information. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table."
  (moin--table-execute-function-per-row 'moin--table-swap-columns nil))


(defun moin--table-move-column-left ()
  "See `moin-command-meta-left' for more information. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table."
  (moin--table-execute-function-per-row 'moin--table-swap-columns t))


(defun moin--table-insert-column ()
  "See `moin-command-meta-shift-right' for more information. Expects
to actually be in a table as prerequisite. Never call this function if
point is currently not in a table."
  (moin--table-execute-function-per-row 'moin--table-do-insert-column nil))


(defun moin--table-remove-column ()
  "See `moin-command-meta-shift-left' for more information. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table."
  (moin--table-execute-function-per-row 'moin--table-do-remove-column nil))


(defun moin--table-move-row-down ()
  "See `moin-command-meta-down' for more information. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table."
  (let (current-column)

    (save-excursion
      ;; Check if there is a row below or this is the last row
      (if (not (moin--table-goto-next-row))
	  (user-error "Cannot move row further")))
    
    (setq current-column (current-column))

    (forward-line)
    (transpose-lines 1)

    (forward-line -1)

    (move-to-column current-column)))


(defun moin--table-move-row-up ()
  "See `moin-command-meta-up' for more information. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table."
  (let (current-column)

    (save-excursion
      ;; Check if there is a row above or this is the first row
      (if (not (moin--table-goto-previous-row))
	  (user-error "Cannot move row further")))
    
    (setq current-column (current-column))

    (transpose-lines 1)

    (forward-line -2)

    (move-to-column current-column)))


(defun moin--table-insert-row (insert-before-p)
  "See `moin-command-meta-shift-down' for more information. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table. If INSERT-BEFORE-P is t, the new
row is inserted before the current row, otherwise it is inserted after
the current row. In any case, it inserts a row with the same number of
columns as the current row."
  (let
      (column-details column-count)

    (setq column-details (moin--table-determine-column-details))
    (setq column-count (- (length column-details) 1))

    (if insert-before-p
	(progn
	  (beginning-of-line)
	  (newline)
	  (forward-line -1))
      (progn
	(end-of-line)
	(newline)))

    (dotimes (i column-count)
      (insert moin-const-empty-field-with-left-delimiter))

    (insert moin-const-table-delimiter)
    
    (move-to-column 3)))


(defun moin--table-remove-row ()
  "See `moin-command-meta-shift-up' for more information. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table."
  (let (current-column
	chars-to-delete
	del-start-point
	del-end-point)

    (setq current-column (current-column))

    (setq del-start-point (point-at-bol))
    (end-of-line)
    
    (if (eobp)
	(setq del-end-point (point-at-eol))
      (progn
	(forward-line)
	(beginning-of-line)
	(setq del-end-point (point-at-bol))))

    (goto-char del-start-point)
    (delete-char (- del-end-point del-start-point))

    (if (and (not (moin-is-in-table-p)) (not (bobp)))
	(progn
	  (forward-line -1)
	  (if (not (moin-is-in-table-p))
	      (forward-line))))

    (if (>= (- (point-at-eol) (point-at-bol)) current-column)
	(move-to-column current-column)
      (move-to-column (- (point-at-eol) (point-at-bol))))))


(defun moin--table-determine-column-details ()
  "Determines the column details of the current row. Expects to
actually be in a table as prerequisite. Never call this function if
point is currently not in a table.

The column details are retruned as a list containing the following
elements:
* The first element is the current table column, i.e. the 1-based
logical column index in the current row where point is currently in,
which then can also be used as index on this entire returned list for
getting the current column details. In the special case that point is
located before the first column content starts, the current column is
nevertheless set to 1. If point is in between the two delimiters of
`moin-const-table-delimiter' of the moin table, it is seen to be still
located in the previous column. In case point is at the end of line,
it is considered to be in the last column.
* All other entries have the form (start-point end-point content)
where 'start-point' is an integer with the buffer's point value of the
first character directly after `moin-const-table-delimiter', i.e.
where the column content begins, 'end-point' is an integer with the
buffer's point value after the last character directly before
`moin-const-table-delimiter', i.e. where the column ends, and
'content' is the actual string content of the column, including any
enclosing whitespace, but without the column delimiters
`moin-const-table-delimiter'."
  (interactive)
  (let
      ((column-regex (concat moin-const-quoted-table-delimiter
			     "\\(.*?\\)" moin-const-quoted-table-delimiter))
       (column-delimiter-size (length moin-const-table-delimiter))
       (current-column 1)
       (return-list (list))
       (initial-point (point))
       (start-point nil)
       (end-point nil)
       (content nil)
       (column-details nil))
    
    (save-excursion
      (beginning-of-line)

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

      (if (< (- initial-point (point-at-bol)) 2)
	  (add-to-list 'return-list 1)
	(if (> initial-point (- (point-at-eol) 2))
	    (add-to-list 'return-list (- current-column 1)))))

    return-list))


(defun moin--table-create (table-size-string)
  "Creates a new table with the given TABLE-SIZE-STRING. If the string
is malformed, it throws a user error."
  (let
      ((error-message (concat
		       "Invalid table size format specified, should be Columns x Rows [e.g. "
		       moin-const-table-default-size "]"))
       (table-size-list (split-string table-size-string "x" t nil))
       cols rows point-before-table)

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
	  (forward-line -1))
      (progn
	(end-of-line)
	(newline)
	(newline)))

    (setq point-before-table (point))
    
    (dotimes (row rows)
      (dotimes (col cols)
	(insert moin-const-empty-field-with-left-delimiter))
      (insert moin-const-table-delimiter)
      (newline))

    (goto-char (+ point-before-table 3))))


;; ==================================================
;; Provide package

(provide 'moin-tables)

;;; moin-tables.el ends here
