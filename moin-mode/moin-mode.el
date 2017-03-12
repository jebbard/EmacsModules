
;; Copyright (C) 2017 Jens Ebert

;; Author: Jens Ebert <jensebert@gmx.net>
;; Maintainer: Jens Ebert <jensebert@gmx.net>
;; Created: 20 Jan 2017
;; Keywords: wiki editing
;; Version: 0.1

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

;; Overview:
;; ---------
;; This is moin-mode which targets to provide a rich editing feeling for
;; MoinMoin 1.9.x wiki pages. See <https://moinmo.in/> for more information
;; regarding MoinMoin. The major editing facilities and syntax highlighting
;; is designed to be quite similar to org mode 8.x.
;; It is possible yet not guaranteed that this mode will work as expected
;; also with other versions of MoinMoin markup, namely Moin 1.8 and below.
;;
;; This major mode tries to make the rather outdated moinmoin-mode.el as found
;; on the following page obsolete:
;; <https://moinmo.in/EmacsForMoinMoin>
;;
;; This is an entirely new major mode for MoinMoin, created from the ground up
;; but surely inspired by the existing work.
;;
;; Installation:
;; -------------
;; * Ensure the file `moin-mode.el' is located in Emacs load
;; path, if this is not the case, use `add-to-list' in your Emacs
;; initialization file, e.g. to .emacs:
;;   (add-to-list 'load-path /my/dir)
;; * Add the following line to your Emacs initialization file:
;;   (require 'moin-mode)
;;
;; User documentation & configuration:
;; -----------------------------------
;; For more details on how to use and configure `moin-mode', see
;; the documentation of the `moin-mode' major mode by typing
;;   M-x describe-function [RET] moin-mode
;; in Emacs. Before this, ensure `moin-mode' is installed as
;; described above.
;;
;; Requirements:
;; -------------
;;
;; * Requires minimum Emacs version 24.0
;;
;; Tests:
;; ------
;; This module has been tested with all combinations of:
;; * OS: Windows 10
;; * Emacs: 24.5
;; * MoinMoin: 1.9.x
;;
;; Improvements:
;; -------------
;; * TBD
::
;; If you have any further suggestions for improvements or enhancements,
;; please mail to <jensebert@gmx.net>

;;; Change Log:
;;
;; v0.1    2017-01-20  Jens Ebert            <jensebert@gmx.net>
;; - initial draft
;; v0.2    2017-02-12  Jens Ebert            <jensebert@gmx.net>
;; - Removed dependency to outshine: outshine introduced subtle bugs for
;;   subtree moving and made it impossible to rebind meta-shift-
;;   <up|down|left|right>
;; - Implemented outline-cycle using bare outline mode commands
;; - Fixed issues in moving subtrees introduced by Emacs outline bug 19102
;;   (for Emacs 24.x, bugfix for bug 19102 from Emacs 25.1 is used)
;; - Fixed some issues with syntax highlighting (errors in *messages*)
;; - Updated outline cycle to also work for headings without any content
;; - Implemented moving of subtrees for headings (up and down)

;;; Code:
;; ==================================================
;; Required mandatory packages

(require 'color)

;; ==================================================
;; Group definitions
(defgroup moin nil
  "Major mode for MoinMoin 1.9.x wiki pages"
  :prefix "moin-")

(defgroup moin-faces nil
  "Faces used for font-lock in moin-mode"
  :prefix "moin-face-"
  :group 'moin)

;; ==================================================
;; Customization options

(defcustom moin-highlight-colored-env-p t
  "Set to t to enable the background color syntax highlighting
of !#wiki environments, set to nil otherwise. Default is t"
  :group 'moin)

(defcustom moin-highlight-colored-table-p t
  "Set to t to enable the background color syntax highlighting
of tables, set to nil otherwise. Default is t"
  :group 'moin)


;; ==================================================
;; Buffer local variables

;; NONE yet

;; ==================================================
;; Face definitions

; ------
; Highlighting Formatted Text
; -------
(defface moin-face-bold '((t (:weight bold)))
  "Face name to use for bold text in moinmoin"
  :group 'moin-faces)
(defface moin-face-italic '((t (:slant italic)))
  "Face name to use for italic text in moinmoin"
  :group 'moin-faces)
(defface moin-face-underline '((t (:underline t)))
  "Face name to use for underlined text in moinmoin"
  :group 'moin-faces)
(defface moin-face-stroke '((t (:strike-through t)))
  "Face name to use for stroked text in moinmoin"
  :group 'moin-faces)
(defface moin-face-subscript '((t (:height 0.8)))
  "Face name to use for subscripts in moinmoin"
  :group 'moin-faces)
(defface moin-face-superscript '((t (:height 0.8)))
  "Face name to use for superscripts in moinmoin"
  :group 'moin-faces)
(defface moin-face-monospace '((t (:family "Courier")))
  "Face name to use for typewriter text in moinmoin"
  :group 'moin-faces)
(defface moin-face-larger '((t (:height 1.1)))
  "Face name to use for larger text in moinmoin"
  :group 'moin-faces)
(defface moin-face-smaller '((t (:height 0.9)))
  "Face name to use for smaller text in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Tables
; -------
(defface moin-face-table-separator
  '((((class color) (background light)) (:foreground "Blue1"))
    (((class color) (background dark)) (:foreground "LightSkyBlue")))
  "Face name to use for separation of columns in tables of moinmoin"
  :group 'moin-faces)
(defface moin-face-table-content
  '((((class color) (background light)) (:foreground "Blue1"))
    (((class color) (background dark)) (:foreground "LightSkyBlue")))
  "Face name to use for separation of columns in tables of moinmoin"
  :group 'moin-faces)
(defface moin-face-table-processing-instruction
  '((((class color) (background light)) (:foreground "DarkGray" :weight bold))
    (((class color) (background dark)) (:foreground "Gray70" :weight bold)))
  "Face name to use for processing instructions in tables of moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Macros
; -------
(defface moin-face-macro-content '((t (:foreground "Dark Blue")))
  "Face name to use for names of macros in moinmoin"
  :group 'moin-faces)
(defface moin-face-macro-braces
  '((((class color) (background light)) (:foreground "Gray70"))
    (((class color) (background dark)) (:foreground "DarkGray")))
  "Face name to use for parameters of macros in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Embeddings (e.g. attachments)
; -------
(defface moin-face-embedding-content '((t (:foreground "Orange")))
  "Face name to use for names of macros in moinmoin"
  :group 'moin-faces)
(defface moin-face-embedding-braces
  '((((class color) (background light)) (:foreground "Gray70"))
    (((class color) (background dark)) (:foreground "DarkGray")))
  "Face name to use for parameters of macros in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Headings
; -------
(defface moin-face-h1
  '((((class color) (background light)) (:height 1.4 :foreground "Blue1"))
    (((class color) (background dark)) (:height 1.4 :foreground "LightSkyBlue")))
  "Face name to use for 1-level headings in moinmoin"
  :group 'moin-faces)
(defface moin-face-h2
  '((((class color) (background light)) (:height 1.3 :foreground "DarkGoldenrod"))
    (((class color) (background dark)) (:height 1.3 :foreground "LightGoldenrod")))
  "Face name to use for 2-level headings in moinmoin"
  :group 'moin-faces)
(defface moin-face-h3
  '((((class color) (background light)) (:height 1.2 :foreground "Purple"))
    (((class color) (background dark)) (:height 1.2 :foreground "Cyan1")))
  "Face name to use for 3-level headings in moinmoin"
  :group 'moin-faces)
(defface moin-face-h4
  '((((class color) (background light)) (:height 1.1 :foreground "Firebrick"))
    (((class color) (background dark)) (:height 1.1 :foreground "chocolate1")))
  "Face name to use for 4-level headings in moinmoin"
  :group 'moin-faces)
(defface moin-face-h5
  '((((class color) (background light)) (:foreground "ForestGreen"))
    (((class color) (background dark)) (:foreground "PaleGreen")))
  "Face name to use for 5-level headings in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Environments
; -------

(defconst moin-face-env-light-fg "grey30"
  "The foreground color to use in a code environment in case of light background")
(defconst moin-face-env-dark-fg "white"
  "The foreground color to use in a code environment in case of dark background")

(defface moin-face-env
  '((((class color) (background light)) (:foreground "grey30" :inherit 'moin-face-monospace))
    (((class color) (background dark)) (:foreground "white" :inherit 'moin-face-monospace)))
  "Face name to use for code inside braces in moinmoin"
  :group 'moin-faces)
(defface moin-face-env-braces
  '((((class color) (background light)) (:foreground "Gray70"))
    (((class color) (background dark)) (:foreground "DarkGray")))
  "Face name to use for baces which delimit environments in moinmoin"
  :group 'moin-faces)
(defface moin-face-env-parser '((t (:foreground "plum3" :weight bold)))
  "Face name to use for parser specs"
  :group 'moin-faces)
(defface moin-face-env-usual-bg
  '((((class color) (background light)) (:background "black" :inherit 'moin-face-monospace))
    (((class color) (background dark)) (:background "white" :inherit 'moin-face-monospace)))
  "Face name to use for parser specs"
  :group 'moin-faces)

; ------
; Links
; -------
(defface moin-face-link
    '((((class color) (background light)) (:foreground "Purple"))
      (((class color) (background dark)) (:foreground "Cyan")))
  "Face name to use for rules in moinmoin"
  :group 'moin-faces)
(defface moin-face-email '((t (:inherit 'moin-face-link :underline t)))
  "Face name to use for emails in moinmoin"
  :group 'moin-faces)
(defface moin-face-link-brackets '((t (:inherit 'moin-face-link :weight bold)))
  "Face name to use for rules in moinmoin"
  :group 'moin-faces)
(defface moin-face-followable-link '((t (:inherit 'moin-face-link :underline t)))
  "Face name to use for rules in moinmoin"
  :group 'moin-faces)
(defface moin-face-wiki-word '((t (:foreground "blue4" :weight bold)))
  "Face name to use for CamelCase links in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting various other elements
; -------
(defface moin-face-rule '((t (:foreground "tomato2" :weight bold)))
  "Face name to use for rules in moinmoin"
  :group 'moin-faces)
(defface moin-face-comment '((t (:foreground "maroon3")))
  "Face name to use for comments in moinmoin"
  :group 'moin-faces)
(defface moin-face-variable '((t (:inherit 'moin-face-monospace)))
  "Face name to use for code inside braces in moinmoin"
  :group 'moin-faces)
(defface moin-face-processing-instruction '((t (:foreground "maroon3")))
  "Face name to use for comments in moinmoin"
  :group 'moin-faces)


;; ==================================================
;; "Private" Functions
(defun moin--create-dynamic-bg-face(bg-color-name)
  "This function dynamically creates a new face symbol for the given 
background color name and sets the background color in the returned face.
It can be used to dynamically change the background color of a piece of 
fontified buffer based on its contents (e.g. background color of a table based
on the specified wiki color). It returns a default background color if the given
color could not be identified (e.g. during typing)."
  (if (color-defined-p bg-color-name)
     (progn
       ; Get the face symbol if already defined before
       (setq face-symbol (intern-soft bg-color-name))

       ; Or create it newly if it wasn't
       (if face-symbol nil
   	(progn
   	  (setq face-symbol (intern (concat "moin-face-env-" bg-color-name)))))
  
       (face-spec-set face-symbol '((t (:inherit 'moin-face-env-usual-bg))))

       (setq rgb-bg-color (color-name-to-rgb bg-color-name))
       (setq r (car rgb-bg-color))
       (setq g (car (cdr rgb-bg-color)))
       (setq b (car (cdr (cdr rgb-bg-color))))

       ; Set the foreground color based on the "darkness" of the bg color
       (if (> (+ r g b) 1.5)
          (setq fg-color-name moin-face-env-light-fg)
   	  (setq fg-color-name moin-face-env-dark-fg))
      
       (set-face-background face-symbol bg-color-name)
       (set-face-foreground face-symbol fg-color-name)
       ;; Return the newly created face symbol  
       face-symbol)
     ;; If no defined color, return the default background color
     'moin-face-env-usual-bg))

(defun moin--setup-font-lock ()
  "Installs all font lock patterns for syntax highlighting in their required order"
  (setq font-lock-multiline t)
  (make-local-variable 'font-lock-extra-managed-props)
  (add-to-list 'font-lock-extra-managed-props 'display)
  (font-lock-add-keywords nil `(
     ; ------
     ; Highlighting Formatted Text
     ; -------
     ;; Bold
     ("\\('''.*?'''\\)"
      (1 'moin-face-bold prepend))
     ;; Italic
     ("[^']+\\(''[^']*?''\\)[^']+"
      (1 'moin-face-italic prepend))
     ;; Underline
     ("\\(__.*?__\\)"
      (1 'moin-face-underline prepend))
     ;; Strikethrough
     ("\\(--(.*?)--\\)"
      (1 'moin-face-stroke prepend))
     ;; Subscript
     ("\\(,,.*?,,\\)"
      (1 (list 'face 'moin-face-subscript 'display '(raise -0.3)) prepend))
     ;; Superscript
     ("\\(\\^.*?\\^\\)"
      (1 (list 'face 'moin-face-superscript 'display '(raise 0.3)) prepend))
     ;; Monospace
     ("\\(`.*?`\\)"
      (1 'moin-face-monospace prepend))
     ;; Larger
     ("\\(~\\+.*?\\+~\\)"
      (1 'moin-face-larger prepend))
     ;; Smaller
     ("\\(~-.*?-~\\)"
      (1 'moin-face-smaller prepend))

     ; ------
     ; Highlighting Tables
     ; -------
     ;; Table content until next separator
     ("\\(.*?\\)\\(||\\)"
      (1 'moin-face-table-content prepend)
      (2 'moin-face-table-separator))
     ;; Table processing instruction
     ("||\\(<.*?>\\)"
      (1 'moin-face-table-processing-instruction prepend))
     ;; Table with color spec
     ("^||<rowbgcolor=\"\\(.*?\\)\">.*$"
      (0 (when moin-highlight-colored-table-p (moin--create-dynamic-bg-face (match-string 1))) prepend))

     ; ------
     ; Highlighting Macros
     ; -------
     ;; Macro
     ("\\(<<\\)\\(.*?\\)\\(>>\\)"
      (1 'moin-face-macro-braces)
      (2 'moin-face-macro-content prepend)
      (3 'moin-face-macro-braces))

     ; ------
     ; Highlighting Embeddings (e.g. Attachment)
     ; -------
     ;; Embedding
     ("\\([^{]{{\\)\\([^{].*?[^}]\\)\\(}}[^}]\\)"
      (1 'moin-face-embedding-braces)
      (2 'moin-face-embedding-content prepend)
      (3 'moin-face-embedding-braces))
    
     ; ------
     ; Highlighting Headings
     ; -------
     ("^\\(= .* =\\)$"
      (1 'moin-face-h1 t))
     ("^\\(== .* ==\\)$"
      (1 'moin-face-h2 t))
     ("^\\(=== .* ===\\)$"
      (1 'moin-face-h3 t))
     ("^\\(==== .* ====\\)$"
      (1 'moin-face-h4 t))
     ("^\\(===== .* =====\\)$"
      (1 'moin-face-h5 t))
    
     ; ------
     ; Highlighting Environments
     ; -------
     ;; One line & multiline code environments with color spec
     ("\\({\\{3,4\\}\\)\\(#!wiki \\([a-z]*?\\)/[a-z]+?$\\)\\([[:ascii:][:nonascii:]]*?\\)\\(}\\{3,4\\}\\)"
      (1 'moin-face-env-braces prepend)
      (2 'moin-face-env-parser prepend)
      (3 'moin-face-env-parser prepend)
      (4 'moin-face-env t)
      (5 'moin-face-env-braces prepend)
      (0 (when moin-highlight-colored-env-p (moin--create-dynamic-bg-face (match-string 3))) prepend))
     ;; One line & multiline code environments with other processing instructions
     ("\\({\\{3,4\\}\\)\\(#![a-z]+ [a-z]+?$\\)\\([[:ascii:][:nonascii:]]*?\\)\\(}\\{3,4\\}\\)"
      (1 'moin-face-env-braces prepend)
      (2 'moin-face-env-parser prepend)
      (3 'moin-face-env t)
      (4 'moin-face-env-braces prepend))
     ;; One line & multiline code environments without color spec
     ("\\({\\{3,4\\}\\)\\([^{#][[:ascii:][:nonascii:]]*?\\)\\(}\\{3,4\\}\\)"
      (1 'moin-face-env-braces prepend)
      (2 'moin-face-env t)
      (3 'moin-face-env-braces prepend))
    
     ; ------
     ; Highlighting Links
     ; -------
     ;; Freehand absolute URL
     ("\\(http\\|https\\|ftp\\|nntp\\|news\\|mailto\\|telnet\\|wiki\\|file\\|irc\\)\\(://[A-Za-z0-9_-+&?%#:./=;$]+\\)"
      (1 'moin-face-followable-link t)
      (2 'moin-face-followable-link t))
     ;; EMail
     ("\\([A-Za-z0-9_+-]+@[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\)"
      (1 'moin-face-email t))
     ;; Explicit Link
     ("\\(\\[\\[\\)\\(.*?\\)\\(\\]\\]\\)"
      (1 'moin-face-link-brackets t)
      (2 'moin-face-link keep)
      (3 'moin-face-link-brackets t))
     ;; Moin WikiWord    
     ("\\(?:^\\|[^A-Za-z!]\\)\\(\\(?:\\.\\./\\)?/?[A-Z][a-z]+[A-Z][a-z][A-Za-z]*\\(?:/[A-Z][a-z]+[A-Z][a-z][A-Za-z]*\\)?\\)"
      (1 'moin-face-wiki-word t))
    
     ; ------
     ; Highlighting various other elements
     ; -------
     ;; Horizontal rules
     ("-\\{4,\\}" (0 'moin-face-rule t))
     ;; Inline commentsm
     ("\\(/\\*.*?\\*/\\)"
      (1 'moin-face-comment t))
     ;; Variables
     ("\\(@.*?@\\)"
      (1 'moin-face-variable t))
     ;; Processing instructions
     ("\\(^#.*$\\)"
      (1 'moin-face-processing-instruction t))
    ) 'set))


(defun moin--setup-key-bindings ()
  "Installs all key bindings"

  ;; Structure editing redefined to org key-bindings and reassociated
  (define-key moin-mode-map (kbd "M-S-<up>") 'moin-command-meta-shift-up)
  (define-key moin-mode-map (kbd "M-S-<down>") 'moin-command-meta-shift-down)
  (define-key moin-mode-map (kbd "M-<up>") 'moin-command-meta-up)
  (define-key moin-mode-map (kbd "M-<down>") 'moin-command-meta-down)

  ;; Promotion / Demotion or table column editing
  (define-key moin-mode-map (kbd "M-S-<left>") 'moin-command-meta-shift-left)
  (define-key moin-mode-map (kbd "M-S-<right>") 'moin-command-meta-shift-right)
  (define-key moin-mode-map (kbd "M-<left>") 'moin-command-meta-left)
  (define-key moin-mode-map (kbd "M-<right>") 'moin-command-meta-right)

  ;; Inserting new elements
  (define-key moin-mode-map (kbd "M-<return>") 'moin-command-meta-return)
  (define-key moin-mode-map (kbd "C-<return>") 'moin-command-insert-heading-respect-content)
  (define-key moin-mode-map (kbd "<return>") 'moin-command-table-next-row)
  
  ;; Moving in tables or Outline cycle (a.k.a. visibility cycling)
  (define-key moin-mode-map [tab] 'moin-command-tab)
  (define-key moin-mode-map (kbd "S-<tab>") 'moin-command-table-previous-field))

(defun moin--determine-heading-level()
  (save-excursion
    (beginning-of-line)
    (looking-at "\\(=+\\) ")
    (setq len (length (match-string 1)))
    len))

(defun moin--determine-heading-folding-state()
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
  ; Second part of or is necessary for headings without any content
  (if (or (invisible-p (point-at-eol)) (invisible-p (- (point-at-eol) 1)))
      "FOLDED"
    ; else
    (save-excursion

      (setq current-heading-level (moin--determine-heading-level))

      ; Set point to next heading (no matter if visible or not)
      (outline-next-heading)
      
      (if (moin-is-on-heading-p)
	  (progn 
	    (setq next-heading-level (moin--determine-heading-level)))
	; else
	(setq next-heading-level 0))

      ; Current heading has children
      (if (and (eq (+ current-heading-level 1) next-heading-level)
	       (invisible-p (point-at-eol)))
	  (progn "CHILDREN")
	; else
	"SUBTREE"))))

(defun moin--move-subtree-down (&optional arg)
  "Move the current subtree down past ARG headlines of the same level.
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
    ; else if emacs major version >= 25
    (outline-move-subtree-dowh arg)))


(defun moin--outline-cycle (&optional arg)
  "Cycles the current heading level between three states, if point is 
currently located on a heading, otherwise delegates to the global binding. 
The states are:
 * FOLDED: Hides the entire subtree and content of the current heading
 * CHILDREN: Shows the content of the current heading and all direct child 
headings of the next lower level below the current heading. The child heading
subtrees remain hidden.
 * SUBTREE: The entire content and subtree below the current heading is 
shown entirely, no folding"
  (interactive "p")
  (if (moin-is-on-heading-p)
      (progn
	(setq folding-state (moin--determine-heading-folding-state))
	;(message "FOLDING state: %s" folding-state)
	
        (cond ((string= "FOLDED" folding-state)
	       (show-entry)
	       (show-children)
	       (message "CHILDREN"))
	      ((string= "CHILDREN" folding-state)
	       (show-subtree)
	       (message "SUBTREE"))
	      ((string= "SUBTREE" folding-state)
	       (hide-subtree)
	       (message "FOLDED"))))
    ; else
    (call-interactively (global-key-binding "\t"))))

;; ==================================================
;; Functions

(defun moin-print-object-at-point()
  "Helper function to check which object is currently at point"
  (interactive)
  (if (moin-is-on-heading-p)
      (message "HEADING")
    (if (moin-is-in-table-p)
	(message "TABLE")
      (if (moin-is-in-list-p)
	  (message "LIST")
      (message "NONE")))))

(defun moin-is-on-heading-p ()
  "Is point on a header line?"
  (outline-on-heading-p))

(defun moin-is-in-table-p ()
  "Is point on a table line?"
  (save-excursion
    (beginning-of-line)
    (looking-at "||")))

(defun moin-is-in-list-p ()
  "Is point on a list line?"
  (save-excursion
    (beginning-of-line)
    (looking-at "\\s-+\\([*.]\\|[1-9A-Za-z]\\.\\)")))

;; ==================================================
;; Commands


(defun moin-command-meta-shift-up (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it basically does the same thing 
as `outline-move-subtree-up': It moves the subtree of the 
current heading to the point before the previous heading of the same 
level, if any. If there is no such heading, it prints an error message. 
* If point is currently in a table, it removes the current row of the
table.
* If point is currently in a list, it moves the current item with its
subtree up (swapping with previous item), if it is not already the first
item below its parent item."
  (interactive "p")
  (moin-command-meta-shift-down  (- arg)))


(defun moin-command-meta-shift-down (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it basically does the same thing 
as `outline-move-subtree-down': It moves the subtree of the 
current heading to the point after the previous heading of the same 
level, if any. If there is no such heading, it prints an error message.
* If point is currently in a table, it creates a new row before the 
current row of the table.
* If point is currently in a list, it moves the current item with its
subtree down (swapping with next item), if it is not already the last
item below its parent item."
  (interactive "p")
  (if (moin-is-on-heading-p)
      (moin--move-subtree-down arg)
    (if (moin-is-in-list-p)
	(user-error "Not implemented yet for lists!")
      (if (moin-is-in-table-p)
	  (user-error "Not implemented yet for tables!")))))


(defun moin-command-meta-up (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it performs the same funtion as 
`moin-command-meta-shift-up', see there. 
* If point is currently in a list, it performs the same function as 
`moin-command-meta-shift-up', see there. 
* If point is currently in a table, it moves the current row up (swapping 
with previous row), if it is not already the first row in the table."
  (interactive "p")
  (if (or (moin-is-on-heading-p) (moin-is-in-list-p))
      (moin-command-meta-shift-up arg)
    (if (moin-is-in-table-p)
	(user-error "Not implemented yet for tables!"))))


(defun moin-command-meta-down (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it performs the same funtion as 
`moin-command-meta-shift-down', see there. 
* If point is currently in a list, it performs the same function as 
`moin-command-meta-shift-down', see there. 
* If point is currently in a table, it moves the current row down (swapping 
with next row), if it is not already the last row in the table."
  (interactive "p")
  (moin-command-meta-shift-up  (- arg)))


(defun moin-command-meta-shift-left (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it promotes the current subtree (i.e.
the current heading and all its children), if the current heading is not
already on level 1. 
* If point is currently in a table, it removes the current column of the
table.
* If point is currently in a list, it decreases the indentation of the
current item with its subtree (i.e. all its children). A subtree's indentation
can only be decreased if it is not already on the left-most indentation level of 
the list."
  (interactive "p")
  (moin-command-meta-shift-right  (- arg)))


(defun moin-command-meta-shift-right (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it demotes the current subtree (i.e.
the current heading and all its children), if the current heading is not
already on level 5. 
* If point is currently in a table, it inserts a new empty column to the 
left of point.
* If point is currently in a list, it increases the indentation of the
current item with its subtree (i.e. all its children). An item's indentation
can only be increased if it is not the first item below its parent."
  (interactive "p")
  (if (moin-is-on-heading-p)
      (user-error "Not implemented yet for headings!")
    (if (moin-is-in-list-p)
	(user-error "Not implemented yet for lists!")
      (if (moin-is-in-table-p)
	  (user-error "Not implemented yet for tables!")))))


(defun moin-command-meta-left (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it demotes the current heading, leaving
its children unchanged, but only if the current heading is not already on level 1. 
* If point is currently in a table, it moves the current column of the
table to the left, but only if it is not already the left-most column.
* If point is currently in a list, it decreases the indentation, leaving its
children unchanged. A single item's indentation can only be decreased if it is
not already on the left-most indentation level of the list. Furthermore, if the
item has children, its indentation can only be decreased by one."
  (interactive "p")
  (moin-command-meta-right  (- arg)))


(defun moin-command-meta-right (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently on a heading, it promotes the current heading, leaving
its children unchanged, but only if the current heading is not already on level 5. 
* If point is currently in a table, it moves the current column of the
table to the right, but only if it is not already the right-most column.
* If point is currently in a list, it increases the indentation, leaving its
children unchanged. An item's indentation can only be increased if it is not the
first item below its parent."
  (interactive "p")
  (if (moin-is-on-heading-p)
      (user-error "Not implemented yet for headings!")
    (if (moin-is-in-list-p)
	(user-error "Not implemented yet for lists!")
      (if (moin-is-in-table-p)
	  (user-error "Not implemented yet for tables!")))))


(defun moin-command-meta-return (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently in a table, it moves to the next row, splitting 
the content of the current cell in two parts starting at point, if point
is currently in the middle of the cell. It creates a new row if point is
currently in the last row. In contrast to org mode, selection or prefix
arguments are not considered, there is no specific functionality for this.
* If point is currently in a list, it inserts a new item with the same
level as one at point. If the comamnd is used in the middle of a list item,
it is split and the text after point is taken as text of the new item. 
The new item is then inserted after the item at point. If point is
currently before the item, the new item is inserted before the current 
item instead.
* Otherwise, including the case that point is currently on a heading, it
inserts a new heading with the same level as the one at point. If the 
command is used in the middle of a heading line, it is split and the text
after point is taken as text of the new heading. The new heading is then 
inserted after the heading at point. If point is currently before the heading,
the new heading is inserted before the current heading instead. If point 
is not in a heading line, the new heading is inserted at point, at the same 
level of the first heading before point. An error message is given if
there is no heading before point."
  (interactive "p")
  (if (moin-is-in-list-p)
      (user-error "Not implemented yet for lists!")
    (if (moin-is-in-table-p)
	(user-error "Not implemented yet for tables!")
      ;; else insert a new headline
      (if (moin-is-on-heading-p)
	(user-error "Not implemented yet for headings!")))))


(defun moin-command-insert-heading-respect-content (&optional arg)
  "Inserts a new heading with the same level of the current heading, 
right after the subtree of the current heading. This also works when only
in the body of a heading."
  (interactive "p")
  (user-error "Not implemented yet!"))


(defun moin-command-table-next-row (&optional arg)
  "When in a table, moves to the next row. On the end of a line, it 
still does NEWLINE and thus can be used to split a table."
  (interactive "p")
  (if (moin-is-in-table-p)
      (if (eolp)
	  (newline)
	(progn
	  (user-error "Not implemented yet!")))
    ; else: Not in table, simply newline
    (newline)))

(defun moin-command-table-previous-field (&optional arg)
  "When in a table, moves to the previous field, if any. The previous field is
 the field to the left of the current one, or in case that the current field 
is in the left-most column, the last field of the previous row."
  (interactive "p")
  ;; It seems impossible to redirect to the mysterious key "S-tab" or also
  ;; called "<backtab>" or "BACKTAB", so we assume nobody needs this...
  (if (moin-is-in-table-p)
      (user-error "Not implemented yet!")))

(defun moin-command-tab (&optional arg)
  "Context-sensitive command that performs different functions based on the
context:
* If point is currently in a table, it moves to the next field to the right,
or to the first field of the next row, if the current field is in the last
column of the table. If the current field is the last field of the table
in the right-most column, this command will create a new empty row and put
point into the left-most field of the new row.
* If point is currently on a heading, it performs visibility cycling, see
`moin--outline-cycle' for more details. "
  (interactive "p")
  (if (moin-is-on-heading-p)
      (moin--outline-cycle arg)
    (if (moin-is-in-table-p)
	(user-error "Not implemented yet for tables!"))))

;; ==================================================
;; Major mode definition

(define-derived-mode moin-mode outline-mode "moin"
  "Set major mode for editing MoinMoin pages"
;  (outline-minor-mode)
  
  ; Preparations for outline minor mode
  (make-local-variable 'outline-regexp)
  (setq outline-regexp "=+ ")
  (make-local-variable 'outline-heading-end-regexp)
  (setq outline-heading-end-regexp " ==*$")
  ; Setup related modes
  (toggle-truncate-lines 0)
  (visual-line-mode 1)
  ; Setup moin internal data
  (moin--setup-key-bindings)
  (moin--setup-font-lock)
  )

;; This is the default naming of revision files for moin moin
;; wiki articles, when saved in file system
(add-to-list 'auto-mode-alist '("[0-9]+\\'" . moin-mode))

;; ==================================================
;; Provide package

(provide 'moin-mode)

;;; moin-mode.el ends here
