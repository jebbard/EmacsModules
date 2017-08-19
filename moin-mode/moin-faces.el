;;; moin-faces.el --- Faces and font-lock for moin mode

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

;; Face definitions for moin mode

;;; Code:

;; ==================================================
;; Required mandatory packages

(require 'color)

;; ==================================================
;; Group definitions

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
;; Constants

(defconst moin-const-format-bold "'''"
  "Bold formatting markup")

(defconst moin-const-format-italic "''"
  "Italic formatting markup")

(defconst moin-const-format-underline "__"
  "Underline formatting markup")


;; ==================================================
;; Face definitions

; ------
; Highlighting Formatted Text
; -------
(defface moin-face-bold '((t (:weight bold)))
  "Face to use for bold text in moinmoin"
  :group 'moin-faces)
(defface moin-face-italic '((t (:slant italic)))
  "Face to use for italic text in moinmoin"
  :group 'moin-faces)
(defface moin-face-underline '((t (:underline t)))
  "Face to use for underlined text in moinmoin"
  :group 'moin-faces)
(defface moin-face-stroke '((t (:strike-through t)))
  "Face to use for stroked text in moinmoin"
  :group 'moin-faces)
(defface moin-face-subscript '((t (:height 0.8)))
  "Face to use for subscripts in moinmoin"
  :group 'moin-faces)
(defface moin-face-superscript '((t (:height 0.8)))
  "Face to use for superscripts in moinmoin"
  :group 'moin-faces)
(defface moin-face-monospace '((t (:family "Courier")))
  "Face to use for monospace text in moinmoin"
  :group 'moin-faces)
(defface moin-face-larger '((t (:height 1.2)))
  "Face to use for larger text in moinmoin"
  :group 'moin-faces)
(defface moin-face-smaller '((t (:height 0.8)))
  "Face to use for smaller text in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Tables
; -------
(defface moin-face-table-separator
  '((((class color) (background light)) (:foreground "Blue1"))
    (((class color) (background dark)) (:foreground "LightSkyBlue")))
  "Face to use for separation of columns in tables of moinmoin"
  :group 'moin-faces)
(defface moin-face-table-content
  '((((class color) (background light)) (:foreground "Blue1"))
    (((class color) (background dark)) (:foreground "LightSkyBlue")))
  "Face to use for tables content in moinmoin"
  :group 'moin-faces)
(defface moin-face-table-processing-instruction
  '((((class color) (background light)) (:foreground "DarkGray" :weight bold))
    (((class color) (background dark)) (:foreground "Gray70" :weight bold)))
  "Face to use for processing instructions in tables of moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Macros
; -------
(defface moin-face-macro-content '((t (:foreground "Dark Blue")))
  "Face to use for names of macros in moinmoin"
  :group 'moin-faces)
(defface moin-face-macro-braces
  '((((class color) (background light)) (:foreground "Gray70"))
    (((class color) (background dark)) (:foreground "DarkGray")))
  "Face to use for macros braces in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Embeddings (e.g. attachments)
; -------
(defface moin-face-embedding-content '((t (:foreground "Orange")))
  "Face to use for cointent of embeddings in moinmoin"
  :group 'moin-faces)
(defface moin-face-embedding-braces
  '((((class color) (background light)) (:foreground "Gray70"))
    (((class color) (background dark)) (:foreground "DarkGray")))
  "Face to use embedding braces in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Headings
; -------
(defface moin-face-h1
  '((((class color) (background light)) (:height 1.4 :foreground "Blue1"))
    (((class color) (background dark)) (:height 1.4 :foreground "LightSkyBlue")))
  "Face to use for level 1 headings in moinmoin"
  :group 'moin-faces)
(defface moin-face-h2
  '((((class color) (background light)) (:height 1.3 :foreground "DarkGoldenrod"))
    (((class color) (background dark)) (:height 1.3 :foreground "LightGoldenrod")))
  "Face to use for level 2 headings in moinmoin"
  :group 'moin-faces)
(defface moin-face-h3
  '((((class color) (background light)) (:height 1.2 :foreground "Purple"))
    (((class color) (background dark)) (:height 1.2 :foreground "Cyan1")))
  "Face to use for level 3 headings in moinmoin"
  :group 'moin-faces)
(defface moin-face-h4
  '((((class color) (background light)) (:height 1.1 :foreground "Firebrick"))
    (((class color) (background dark)) (:height 1.1 :foreground "chocolate1")))
  "Face to use for level 4 headings in moinmoin"
  :group 'moin-faces)
(defface moin-face-h5
  '((((class color) (background light)) (:foreground "ForestGreen"))
    (((class color) (background dark)) (:foreground "PaleGreen")))
  "Face to use for level 5 headings in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting Environments
; -------

(defconst moin-face-env-light-fg "grey30"
  "Face to use in a code environment in case of light background")
(defconst moin-face-env-dark-fg "white"
  "Face to use in a code environment in case of dark background")

(defface moin-face-env
  '((((class color) (background light)) (:foreground "grey30" :inherit 'moin-face-monospace))
    (((class color) (background dark)) (:foreground "white" :inherit 'moin-face-monospace)))
  "Face to use for code inside braces in moinmoin"
  :group 'moin-faces)
(defface moin-face-env-braces
  '((((class color) (background light)) (:foreground "Gray70"))
    (((class color) (background dark)) (:foreground "DarkGray")))
  "Face to use for baces which delimit environments in moinmoin"
  :group 'moin-faces)
(defface moin-face-env-parser '((t (:foreground "plum3" :weight bold)))
  "Face to use for parser specs"
  :group 'moin-faces)
(defface moin-face-env-usual-bg
  '((((class color) (background light)) (:background "black" :inherit 'moin-face-monospace))
    (((class color) (background dark)) (:background "white" :inherit 'moin-face-monospace)))
  "Face to use for usual code env background"
  :group 'moin-faces)

; ------
; Links
; -------
(defface moin-face-link
    '((((class color) (background light)) (:foreground "Purple"))
      (((class color) (background dark)) (:foreground "Cyan")))
  "Face to use for link content in moinmoin"
  :group 'moin-faces)
(defface moin-face-email '((t (:inherit 'moin-face-link :underline t)))
  "Face to use for emails in moinmoin"
  :group 'moin-faces)
(defface moin-face-link-brackets '((t (:inherit 'moin-face-link :weight bold)))
  "Face to use for link brackets in moinmoin"
  :group 'moin-faces)
(defface moin-face-followable-link '((t (:inherit 'moin-face-link :underline t)))
  "Face to use for a url in moinmoin"
  :group 'moin-faces)
(defface moin-face-wiki-word '((t (:foreground "blue4" :weight bold)))
  "Face to use for WikiWords in moinmoin"
  :group 'moin-faces)

; ------
; Highlighting various other elements
; -------
(defface moin-face-rule '((t (:foreground "tomato2" :weight bold)))
  "Face to use for rules in moinmoin"
  :group 'moin-faces)
(defface moin-face-comment '((t (:foreground "maroon3")))
  "Face to use for comments in moinmoin"
  :group 'moin-faces)
(defface moin-face-variable '((t (:inherit 'moin-face-monospace)))
  "Face to use for variables in moinmoin"
  :group 'moin-faces)


;; ==================================================
;; "Private" Functions
(defun moin--create-dynamic-bg-face(bg-color-name)
  "This function dynamically creates a new face symbol for the given
BG-COLOR-NAME and sets the background color in the returned face. It
can be used to dynamically change the background color of a piece of
fontified buffer based on its contents (e.g. background color of a
table based on the specified wiki color). It returns a default
background color if the given color could not be identified (e.g.
during typing)."
  (let (face-symbol
	rgb-bg-color
	r
	g
	b
	fg-color-name)
    
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

          ;; Set the foreground color based on the "darkness" of the bg color
	  (if (> (+ r g b) 1.5)
	      (setq fg-color-name moin-face-env-light-fg)
	    (setq fg-color-name moin-face-env-dark-fg))
	  
	  (set-face-background face-symbol bg-color-name)
	  (set-face-foreground face-symbol fg-color-name)
	  ;; Return the newly created face symbol  
	  face-symbol)
      ;; If no defined color, return the default background color
      'moin-face-env-usual-bg)))


(defun moin--code-environment-matcher (bound)
  "Matcher to find multiline code environments, searching from current
point up to BOUND. Returns t if it finds that a code environment
starts after point and ends before point + BOUND. Returns nil
otherwise."
  (let (start-brace-begin
	start-brace-end
	pi-begin
	pi-end
	code-begin
	code-end
	end-brace-begin
	end-brace-end
	not-first-line)
    
    (catch 'match
      (while (< (point) bound)
	(unless (search-forward-regexp "{{{{\\|{{{" bound t)
	  (throw 'match nil))
	
	(let ((start-brace-begin (match-beginning 0))
	      (start-brace-end (match-end 0))
	      pi-begin
	      pi-end
	      pi-color-begin
	      pi-color-end
	      code-begin
	      code-end
	      end-brace-begin
	      end-brace-end)
	  
	  (unless (get-text-property start-brace-begin 'moin-verb)
	    (goto-char start-brace-end)

	    ;; Processing instruction with color
	    (if (looking-at "#!wiki \\([a-z]*?\\)/[a-z]+?$")
		(progn
		  (setq pi-begin (match-beginning 0))
		  (setq pi-end (match-end 0))
		  (setq pi-color-begin (match-beginning 1))
		  (setq pi-color-end (match-end 1))
		  (setq code-begin (match-end 0)))
	      ;; Other processing instructions
	      (if (looking-at "#!.*$")
		  (progn
		    (setq pi-begin (match-beginning 0))
		    (setq pi-end (match-end 0))
		    (setq code-begin (match-end 0)))
		(setq code-begin start-brace-end)))
	    
	    (goto-char code-begin)
	    
	    (while (looking-at
		    "\\(?:.*?\\|{{{{.*?}}}}\\|{{{.*?}}}\\|.\\)*?\\(?:\\(}}}}\\|}}}\\)\\|\n\\)")
	      (goto-char (match-end 0))
	      
	      ;; We found the end of the code environment or a line end (match group 1 is non-nil)
	      (when (and (match-beginning 1) not-first-line)

		(setq code-end (match-beginning 1)
		      end-brace-begin (match-beginning 1)
		      end-brace-end (match-end 1))

		;; These are the group positions (start end) to highlight
		(set-match-data (list start-brace-begin end-brace-end
				      start-brace-begin start-brace-end
				      pi-begin          pi-end
				      pi-color-begin    pi-color-end
				      code-begin        code-end
				      end-brace-begin   end-brace-end))
		(throw 'match t))
	      (setq not-first-line t))
	    (throw 'match nil)))))))


(defun moin--setup-font-lock ()
  "Installs all font lock patterns for syntax highlighting in their
required order"
  (setq font-lock-multiline t)
  (make-local-variable 'font-lock-extra-managed-props)
  (add-to-list 'font-lock-extra-managed-props 'display)
  (add-to-list 'font-lock-extra-managed-props 'moin-verb)
  (font-lock-add-keywords nil `(
     
     ;; *******
     ;; Highlighting Environments
     ;;				
     ;; Requirements:
     ;; - Environments may start and end with three or four braces
     ;; - They are always multiline, in a sense that the content of the environment
     ;;   must start in the next line after the enviornment
     ;; - Text might be before the start of an environment on the same line or after the
     ;;   end of the environment on the same line
     ;; - Headings or tables are not highlighted in environments
     ;; - Formatting (bold, italic etc.) is not highlighted in environments
     ;; - WikiWords, Macros, Links or Variables are not highlighted in environments
     ;; *******
     (moin--code-environment-matcher
      (0 (when (and moin-highlight-colored-env-p (match-string 3)) (moin--create-dynamic-bg-face (match-string 3))) keep)
      (1 (list 'face 'moin-face-env-braces 'moin-verb t) keep)
      (2 (list 'face 'moin-face-env-parser 'moin-verb t) keep t)
      (3 (list 'face 'moin-face-env-parser 'moin-verb t) keep t)
      (4 (list 'face 'moin-face-env        'moin-verb t) keep)
      (5 (list 'face 'moin-face-env-braces 'moin-verb t) keep))
    
     ;; *******
     ;; Highlighting Headings
     ;;				
     ;; Requirements:
     ;; - Headings are only highlighted if in one line and if not malformed
     ;; - Formatting (bold, italic etc.) is not highlighted in headings
     ;; - WikiWords, Macros, Links, Attachments or Variables
     ;;   are not highlighted in Headings
     ;; *******
     ("^\\(= .* =\\)$"
      (1 'moin-face-h1 keep))
     ("^\\(== .* ==\\)$"
      (1 'moin-face-h2 keep))
     ("^\\(=== .* ===\\)$"
      (1 'moin-face-h3 keep))
     ("^\\(==== .* ====\\)$"
      (1 'moin-face-h4 keep))
     ("^\\(===== .* =====\\)$"
      (1 'moin-face-h5 keep))

     ;; *******
     ;; Highlighting Macros
     ;;				
     ;; Requirements:
     ;; - Macros start and end on the same line
     ;; - Macros are highlighted if within formatted text
     ;; - They are highlighted in tables, but not in code environments or headings
     ;; *******
     ;; Macro
     ("\\(<<\\)\\(.*?\\)\\(>>\\)"
      (1 'moin-face-macro-braces keep)
      (2 'moin-face-macro-content keep)
      (3 'moin-face-macro-braces keep))
    
     ;; *******
     ;; Highlighting Formatted Text
     ;;				
     ;; Requirements:
     ;; - Formatting that overlaps each other is only supported for bold and italic
     ;;   i.e. starting a new formatting inside an existing formatted text might
     ;;   not be highlighted correctly
     ;; - Formatting is not highlighted in headings, environments or links
     ;; - Formatting is highlighted in tables
     ;; - Although MoinMoin seems to support formatting crossing multiple lines,
     ;;   this mode does not support this
     ;; - Known issue: Subscripts and superscripts are always highlighted, even in
     ;;   headings and environments
     ;; *******
     ;; Bold in italic
     ("\\(''.*?\\)\\('''.*?'''\\)\\(.*?''\\)"
      (1 'moin-face-italic keep)
      (2 'moin-face-bold keep)
      (3 'moin-face-italic keep))
     ;; Italic in bold
     ("\\('''.*?\\)\\(''.*?''\\)\\(.*?'''\\)"
      (1 'moin-face-bold keep)
      (2 'moin-face-italic keep)
      (3 'moin-face-bold keep))
     ;; Bold
     ("\\('''.*?'''\\)"
      (1 'moin-face-bold keep))
     ;; Italic
     ("\\(''.*?''\\)"
      (1 'moin-face-italic keep))
     ;; Underline
     ("\\(__.*?__\\)"
      (1 'moin-face-underline keep))
     ;; Strikethrough
     ("\\(--(.*?)--\\)"
      (1 'moin-face-stroke keep))
     ;; Subscript
     ("\\(,,.*?,,\\)"
      (1 (list 'face 'moin-face-subscript 'display '(raise -0.3)) keep))
     ;; Superscript
     ("\\(\\^.*?\\^\\)"
      (1 (list 'face 'moin-face-superscript 'display '(raise 0.3)) keep))
     ;; Monospace
     ("\\(`.*?`\\)"
      (1 'moin-face-monospace keep))
     ;; Larger
     ("\\(~\\+.*?\\+~\\)"
      (1 'moin-face-larger keep))
     ;; Smaller
     ("\\(~-.*?-~\\)"
      (1 'moin-face-smaller keep))

     ;; *******
     ;; Highlighting Embeddings (e.g. Attachment)
     ;;				
     ;; Requirements:
     ;; - Embeddings cannot span multiple lines
     ;; - Embeddings are also highlighted in tables
     ;; *******
     ("\\([^{]{{\\)\\([^{].*?[^}]\\)\\(}}[^}]\\)"
      (1 'moin-face-embedding-braces keep)
      (2 'moin-face-embedding-content keep)
      (3 'moin-face-embedding-braces keep))
    
     ;; *******
     ;; Highlighting Links
     ;;				
     ;; Requirements:
     ;; - Freehand links are highlighted, but only until the first whitespace character
     ;; - Links are also highlighted in tables
     ;; - They cannot span multiple lines
     ;; *******
     ;; Freehand absolute URL
 ("\\(http\\|https\\|ftp\\|nntp\\|news\\|mailto\\|telnet\\|wiki\\|file\\|irc\\)\\(://[A-Za-z0-9_-+&?%#:./=;$]+\\)"
      (1 'moin-face-followable-link keep)
      (2 'moin-face-followable-link keep))
     ;; EMail
     ("\\([A-Za-z0-9_+-]+@[A-Za-z0-9_-]+\\.[A-Za-z0-9_-]+\\)"
      (1 'moin-face-email keep))
     ;; Explicit Link
     ("\\(\\[\\[\\)\\(.*?\\)\\(\\]\\]\\)"
      (1 'moin-face-link-brackets keep)
      (2 'moin-face-link keep)
      (3 'moin-face-link-brackets keep))
     ;; Moin WikiWord    
     ("\\(?:^\\|[^A-Za-z!]\\)\\(\\(?:\\.\\./\\)?/?[A-Z][a-z]+[A-Z][a-z][A-Za-z]*\\(?:/[A-Z][a-z]+[A-Z][a-z][A-Za-z]*\\)?\\)"
      (1 'moin-face-wiki-word keep))
    
     ;; *******
     ;; Highlighting various other elements
     ;;				
     ;; Requirements:
     ;; - Comments and variables are higlighted in tables, but not in headings or code environments
     ;; - They must not span multiple lines
     ;; *******
     ;; Horizontal rules
     ("-\\{4,\\}" (0 'moin-face-rule keep))
     ;; Inline commentsm
     ("\\(/\\*.*?\\*/\\)"
      (1 'moin-face-comment keep))
     ;; Variables
     ("\\(@[a-zA-Z0-9]*?@\\)"
      (1 'moin-face-variable keep))

     ;; *******
     ;; Highlighting Tables
     ;;				
     ;; Requirements:
     ;; - Table delimiters must be at start and end of line to be highlighted as table
     ;; - Formatting, Links, Wikiwords, Macros and Variables are highlighted in tables
     ;; *******
     ;; Table content until next separator incl. table processing instructions
     ("||\\(<.*?>\\)"
      (1 'moin-face-table-processing-instruction append))
     ;; Table with color spec
     ("^||<rowbgcolor=\"\\(.*?\\)\">.*$"
       (0 (when moin-highlight-colored-table-p (moin--create-dynamic-bg-face (match-string 1))) append))
     ("\\(.*?\\)\\(||\\)"
      (1 'moin-face-table-content append)
      (2 'moin-face-table-separator append))
    ) 'set))


(provide 'moin-faces)

;;; moin-faces.el ends here
