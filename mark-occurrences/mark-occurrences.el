;;; mark-occurrences.el --- Support for the mark-occurrences-mode

;; Copyright (C) 2015 Jens Ebert

;; Author: Jens Ebert <jensebert@gmx.net>
;; Maintainer: Jens Ebert <jensebert@gmx.net>
;; Created: 08 Nov 2015
;; Keywords: convenience
;; Version: 0.5

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
;; This is mark-occurrences-mode which allows to mark words or strings
;; in the buffer by using <double-mouse-1> selection.
;;
;; Installation:
;; -------------
;; * Ensure the file `mark-occurrences-mode.el' is located in Emacs load
;; path, if this is not the case, use `add-to-list' in your Emacs
;; initialization file, e.g. to .emacs:
;;   (add-to-list 'load-path /my/dir)
;; * Add the following line to your Emacs initialization file:
;;   (require 'mark-occurrences-mode)
;;
;; User documentation & configuration:
;; -----------------------------------
;; For more details on how to use and configure `mark-occurrences-mode', see
;; the documentation of the `mark-occurrences-mode' minor mode by typing
;;   M-x describe-function [RET] mark-occurrences-mode
;; in Emacs. Before this, ensure `mark-occurrences-mode' is installed as
;; described above.
;;
;; Improvements:
;; -------------
;; * I am planning to provide automatic highlighting also when selecting a word
;; or phrase via keybord (e.g. with C-SPACE, or with shift select) and via
;; mouse drag selection. As this is not too straight-forward and might
;; interfere with some default functionality, I left this to future releases.
;; * Furthermore, case-insensitive highlighting might proof helpful sometimes.
::
;; If you have any further suggestions for improvements or enhancements,
;; please mail to <jensebert@gmx.net>

;;; Change Log:
;;
;; v0.5    2015-11-09  Jens Ebert            <jensebert@gmx.net>
;; - initial version

;;; Code:
;; ==================================================
;; The group

(defgroup mo nil
  "Highlight term selected by double-mouse-1 clicks."
  :version "24.4"
  :group 'convenience)

;; ==================================================
;; Predefined color series

(defconst mo-green-series
  (list "mo-green-series-1" "mo-green-series-2" "mo-green-series-3"
	"mo-green-series-4" "mo-green-series-5"))

(defconst mo-orange-series
  (list "mo-orange-series-1" "mo-orange-series-2" "mo-orange-series-3"
   "mo-orange-series-4" "mo-orange-series-5"))

(defconst mo-yellow-series
  (list "mo-yellow-series-1" "mo-yellow-series-2" "mo-yellow-series-3"
   "mo-yellow-series-4" "mo-yellow-series-5"))

(defconst mo-red-series
  (list "mo-red-series-1" "mo-red-series-2" "mo-red-series-3"
   "mo-red-series-4" "mo-red-series-5"))

(defconst mo-blue-series
  (list "mo-blue-series-1" "mo-blue-series-2" "mo-blue-series-3"
   "mo-blue-series-4" "mo-blue-series-5"))

(defconst mo-gray-series
  (list "mo-gray-series-1" "mo-gray-series-2" "mo-gray-series-3"
   "mo-gray-series-4" "mo-gray-series-5"))

(defconst mo-moderate-series
  (list "mo-green-series-1" "mo-blue-series-1" "mo-yellow-series-1"
   "mo-orange-series-1" "mo-red-series-1"))

(defconst mo-strong-series
  (list "mo-green-series-5" "mo-blue-series-5" "mo-yellow-series-5"
   "mo-orange-series-5" "mo-red-series-5"))

;; ==================================================
;; Customization options

(defcustom mo-wait-time-sec 0.6
  "The time to wait in seconds before highlighting a selection.
The selection must be active for the given time, and only then 
it is highlighted in the current buffer. The default value
of 600 ms turned out to be convenient for most users."
  :group 'mo)

(defcustom mo-faces-to-use mo-green-series
  "A list of faces to use for highlighting. The order of the 
faces determines which faces are used in which order. As much
as `(len mo-faces-to-use)' different selections in the buffer 
can be highlighted at the same time. So you can set this 
variable to a different list - not only to change the faces to use,
but also if  you want to either increase or decrease the 
maximum number of parallel marked occurrences in a single buffer.
If you do not like the default faces in this list, you can 
e.g. set it to `hi-lock-face-defaults' or provide your own 
combination of colors using the faces defined in `mark-occurrences-mode',
in the order you require it. By default, `mark-occurrences-mode' 
defines several sets of 5 consecutive colors: `mo-green-series', 
`mo-orange-series', `mo-yellow-series', `mo-red-series', `mo-blue-series',
`mo-gray-series', `mo-strong-series', `mo-moderate-series'.
Alternatively, you define your own faces and set the variable to 
this list."
  :group 'mo)

;; ==================================================
;; Buffer local variables

(make-variable-buffer-local
 (defvar next-face-index 0
   "The index of the next highlight face"))

;; ==================================================
;; Face definitions

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Green series
;;;;;;;;;;;;;;;;;;;;;;;;;
(defface mo-green-series-1
   '((((background dark)) (:background "pale green" :foreground "black"))
     (t (:background "pale green" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-green-series-2
   '((((background dark)) (:background "lawn green" :foreground "black"))
     (t (:background "lawn green" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-green-series-3
   '((((background dark)) (:background "yellow green" :foreground "black"))
     (t (:background "yellow green" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-green-series-4
   '((((background dark)) (:background "lime green" :foreground "black"))
     (t (:background "lime green" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-green-series-5
   '((((background dark)) (:background "medium sea green" :foreground "black"))
     (t (:background "medium sea green" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)


;;;;;;;;;;;;;;;;;;;;;;;;;
;; Orange series
;;;;;;;;;;;;;;;;;;;;;;;;;
(defface mo-orange-series-1
   '((((background dark)) (:background "light goldenrod" :foreground "black"))
     (t (:background "light goldenrod" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-orange-series-2
   '((((background dark)) (:background "sandy brown" :foreground "black"))
     (t (:background "sandy brown" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-orange-series-3
   '((((background dark)) (:background "gold" :foreground "black"))
     (t (:background "gold" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-orange-series-4
   '((((background dark)) (:background "goldenrod" :foreground "black"))
     (t (:background "goldenrod" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-orange-series-5
   '((((background dark)) (:background "chocolate" :foreground "black"))
     (t (:background "chocolate" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Yellow series
;;;;;;;;;;;;;;;;;;;;;;;;;
(defface mo-yellow-series-1
   '((((background dark)) (:background "LightYellow3" :foreground "black"))
     (t (:background "LightYellow3" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-yellow-series-2
   '((((background dark)) (:background "khaki1" :foreground "black"))
     (t (:background "khaki1" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-yellow-series-3
   '((((background dark)) (:background "yellow" :foreground "black"))
     (t (:background "yellow" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-yellow-series-4
   '((((background dark)) (:background "yellow3" :foreground "black"))
     (t (:background "yellow3" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-yellow-series-5
   '((((background dark)) (:background "gold1" :foreground "black"))
     (t (:background "gold1" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Red series
;;;;;;;;;;;;;;;;;;;;;;;;;
(defface mo-red-series-1
   '((((background dark)) (:background "bisque" :foreground "black"))
     (t (:background "bisque" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-red-series-2
   '((((background dark)) (:background "dark salmon" :foreground "black"))
     (t (:background "dark salmon" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-red-series-3
   '((((background dark)) (:background "tomato" :foreground "black"))
     (t (:background "tomato" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-red-series-4
   '((((background dark)) (:background "indian red" :foreground "black"))
     (t (:background "indian red" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-red-series-5
   '((((background dark)) (:background "orange red" :foreground "black"))
     (t (:background "orange red" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Blue series
;;;;;;;;;;;;;;;;;;;;;;;;;
(defface mo-blue-series-1
   '((((background dark)) (:background "LightBlue1" :foreground "black"))
     (t (:background "LightBlue1" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-blue-series-2
   '((((background dark)) (:background "light steel blue" :foreground "black"))
     (t (:background "light steel blue" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-blue-series-3
   '((((background dark)) (:background "sky blue" :foreground "black"))
     (t (:background "sky blue" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-blue-series-4
   '((((background dark)) (:background "deep sky blue" :foreground "black"))
     (t (:background "deep sky blue" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-blue-series-5
   '((((background dark)) (:background "dodger blue" :foreground "black"))
     (t (:background "dodger blue" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

;;;;;;;;;;;;;;;;;;;;;;;;;
;; Gray series
;;;;;;;;;;;;;;;;;;;;;;;;;
(defface mo-gray-series-1
   '((((background dark)) (:background "white smoke" :foreground "black"))
     (t (:background "white smoke" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-gray-series-2
   '((((background dark)) (:background "gainsboro" :foreground "black"))
     (t (:background "gainsboro" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-gray-series-3
   '((((background dark)) (:background "gray" :foreground "black"))
     (t (:background "gray" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-gray-series-4
   '((((background dark)) (:background "light slate gray" :foreground "black"))
     (t (:background "light slate gray" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

(defface mo-gray-series-5
   '((((background dark)) (:background "dim gray" :foreground "black"))
     (t (:background "dim gray" :foreground "black")))
   "Face for mark-occurrences-mode."
  :group 'mo)

;; ==================================================
;; "Private" Functions

(defun mo--enable-hi-lock()
  "Enables hi-lock-mode if not yet enabled"
  (require 'hi-lock)
  (unless (bound-and-true-p hi-lock-mode)
      (hi-lock-mode 1)))

(defun mo--trim-string (string)
  "Remove white spaces in beginning and ending of STRING.
White space here is any of: space, tab, emacs newline (line feed, ASCII 10)."
  (replace-regexp-in-string "\\`[ \t\n]*" "" (replace-regexp-in-string
					      "[ \t\n]*\\'" "" string)))

;; ==================================================
;; Functions

(defun mo-mark-occurrences(&optional word)
  "Mark occurrences of the string corresponding to the currently marked 
region in the current buffer. If the optional argument WORD is 
given and evaluated to t, only whole words will be highlighted.
This will also enable `hi-lock-mode', if currently disabled.
Both the faces to use for highlighting (in defined order) as
well as the maximum number of occurrences marked by this method
in the same buffer can be configured using the `mo-faces-to-use' 
variable."
  (interactive)
  (mo--enable-hi-lock)
  
  (if mark-active
      (progn
	;; Get current region
	(setq region-string (buffer-substring-no-properties (mark) (point)))

	(setq trimmed-region-string (mo--trim-string region-string))
	
	(unless (= 0 (length trimmed-region-string))
	  (progn
	    (setq len (length mo-faces-to-use))
	    
	    (if (= len next-face-index)
		;; Having highlighted the maximum number of words,
		;; unhighlight again to ensure the buffer does not
		;; look like a christmas tree anymore
		(progn
		  (mo-unmark-all)))
	    
	    (setq face-to-use (nth next-face-index mo-faces-to-use))
	    
	    (if word
		;; Highlight whole words only
		(progn
		  (setq regexp-to-highlight (concat "\\<" region-string "\\>")))
	      ;; else: Highlight every match
	      (progn
		(setq regexp-to-highlight region-string)))
	    (setq next-face-index (1+ next-face-index))
	    (highlight-regexp regexp-to-highlight face-to-use))))))



(defun mo-unmark-all()
  "Unmark all previously marked occurrences.
This will also enable `hi-lock-mode', if currently disabled. 
After this command has been executed, the next `mo-mark-occurrences'
execution will start with the initial face in `mo-faces-to-use' again."
  (interactive)
  (mo--enable-hi-lock)
  (dolist (current-pattern hi-lock-interactive-patterns)
    (unhighlight-regexp (car current-pattern)))
  (setq next-face-index 0))

;; ==================================================
;; Commands

(defun mo--trigger-mouse-highlight(event)
  "Trigger highlighting of currently marked region after mouse click, and 
after waiting for specified `mo-wait-time-sec'. It marks all strings in the
buffer that match the given region content, no matter if they are whole words
or only part of a word."
    (interactive "e")
    (run-with-idle-timer mo-wait-time-sec nil 'mo-mark-occurrences)
    ; Propagate event to ensure the double click gets processed as usual
    (mouse-drag-region event))



(defun mo--trigger-mouse-highlight-word-only(event)
  "Trigger highlighting of currently marked word after mouse click, and 
after waiting for specified `mo-wait-time-sec'."
    (interactive "e")
    (require 'misc)
    (run-with-idle-timer mo-wait-time-sec nil 'mo-mark-occurrences t)
    
    ;; Mark the word the mouse was clicking on
     ; Discard first entry (which is key)
    (pop event)
    (setq event-details (pop event))
     ; Discard first details entry
    (pop event-details)
    
    (setq click-pos (car event-details))
    (goto-char click-pos)
    ;; The following "forward, then backward" ensures
    ;; that selection works the same way as simple
    ;; double-click, i.e. a word is also selected if you click
    ;; at the beginning of the word
    (forward-word)
    (backward-word)
    (mark-word))

;; ==================================================
;; Minor mode definition

;;;###autoload
(define-minor-mode mark-occurrences-mode
  "This is an Emacs minor mode that highlights all occurrences of a selected 
string in various faces. The highlighting and unhighlighting can be triggered 
using mouse double clicks.

In vanilla Emacs v24, double-clicking a word in text already selects it, but 
this does not lead to any highlighting of the word in the buffer by default.

Notepad++ has a similar functionality as `mark-occurrences-mode' offers. If 
you select a complete word in Notepad++ (e.g. via <double-mouse-1>), the word 
will be highlighted in the file. However, this functionality in Notepad++ much
 more limited, because:
* Highlighting will disappear as soon as the cursor moves. In contrast to that,
in `mark-occurrences-mode' all highlights will remain, no matter if you change
the cursor position, select another word or phrase, or change to another buffer.
* Only complete words can be highlighted. 
* Only one word at a time can be highlighted

The `mark-occurrences-mode' is also similar to what you might know as 'mark 
occurrences' in Eclipse. However, `mark-occurrences-mode' of course does not 
consider any symbol scope of any programming language.

Note that mark occurrences mode in no way can replace the existing `hi-lock-mode', 
because the latter is much more powerful due to ability to use arbitrary regular 
expressions. However, `mark-occurrences-mode' can be a convenient enhancement by
providing ad-hoc highlighting similar to what the editors mentioned above offer.

Features:
---------

* You can enable or disable this minor mode in the current buffer by typing 
M-x mark-occurrences-mode. This will show the string 'MO' in the mode line to 
indicate this mode is active.
* You can enable `mark-occurrences-mode' globally by calling
`global-mark-occurrences-mode' with a positive argument e.g. in your Emacs 
initialization file by using (global-mark-occurrences-mode 1)
* If this mode is active, using <double-mouse-1> on text will select the word you 
clicked (Emacs 24 default behavior), and if the word is selected for an amount of 
`mo-wait-time-sec' seconds, the string corresponding to the word will be 
highlighted in the whole buffer.
* We intentionally said 'string' because the phrase will be highlighted no 
matter if it forms a complete or only a part of a word. E.g. if you select the
word 'the' in the buffer by double-clicking with mouse 1, then also the three 
first letters of every occurrence of the word 'theme' in the buffer will be 
highlighted, too.
* You can modify `mo-wait-time-sec' to an amount of time that is most convenient
for you.
* To select words only, use <S-C-double-mouse-1> instead of <double-mouse-1>.
* This way, you can highlight a virtually arbitrary number of phrases in the 
current buffer, only limited by the number of distinct face names in the list 
`mo-faces-to-use'.
* This library provides the following default sets - each with 5 consecutive 
colors - to choose from, starting with a rather moderate color and ending with 
a strong color:
  * `mo-green-series': Default series set with green tones
  * `mo-orange-series': Orange tones
  * `mo-yellow-series': Yellow tones
  * `mo-red-series': Red tones
  * `mo-blue-series': Blue tones
  * `mo-gray-series': Grayish tones
  * `mo-strong-series': A set of strong, easily distinguishable eye-catchers
  * `mo-moderate-series': Equally distinguishable, but mostly moderate colors
* If you do not like the default faces, you need more or less of
them, simply change the value of this list. You can use self-defined faces, for
some example of a face look at e.g. `mo-green-set-1'. Use
    (setq mo-faces-to-use my-face-list)
to set your very own individual list of faces to use for highlighting.
* To unhighlight all currently highlighted phrases in the buffer, use 
M-x mo-unmark-all, which is by default bound to <double-mouse-3>, i.e. right 
mouse button.
* You can highlight single characters if they form a word, except whitespace 
(see 'Non-Features'). Although, usually highlighting all occurrences of single 
letters or digits in a buffer might not be very useful.
* For optimized readability, the default color sets to choose use a black
foreground color. This ensures a contrast to the background highlighting no 
matter what the original foreground of the highlighted text was. Simply choose
colors that omit the foreground color if you want to keep foreground colors 
untouched by highlighting.

Non-features:
-------------
* Highlighting will not be triggered when selecting words, word parts or multiple
words with the keyboard (e.g. C-SPACE, shift select etc.) or with mouse-1 + drag.
* Saying this and looking at the above features, this also means: You can only 
start highlighting by selecting a word via double-clicking. Depending on the 
selection mode (i.e. using <double-mouse-1> or <S-C-double-mouse-1>) this will
either keep to words or also consider word parts.
* Note that you cannot highlight whitespace using `mark-occurrences-mode', for 
this we suggest to use e.g. `whitespace-mode' instead.
* Furthermore, note that highlighting is case-sensitive, e.g. if you select 
the word 'fly' for highlighting in the current buffer, capital letter 'Fly's, 
'fLy's or 'FLY's won't be highlighted.
"
  :group 'mo
  :lighter " MO"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "<double-down-mouse-1>")
	      'mo--trigger-mouse-highlight)
            (define-key map (kbd "C-S-<double-mouse-1>")
	      'mo--trigger-mouse-highlight-word-only)
            (define-key map (kbd "<double-down-mouse-3>")
	      'mo-unmark-all)
            map)
  ; Enabling the mode
  (unless mark-occurrences-mode
    (progn
      (mo-unmark-all)
      (hi-lock-mode -1))))

;; ==================================================
;; Provide global mode and package

;;;###autoload
(define-globalized-minor-mode global-mark-occurrences-mode mark-occurrences-mode
  (lambda () (unless (minibufferp) (mark-occurrences-mode))))

(provide 'mark-occurrences)

;;; mark-occurrences.el ends here
