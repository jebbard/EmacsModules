# EmacsModules

A collection of Emacs modules to improve productivity when working with the greatest editor of all times. I hope some of these modules will be useful for some Emacs users.

## mark-occurrences
This module is a convenience front-end to the standard Emacs `hi-lock-mode`. It allows you to highlight words or parts of words based on double-left-cklick mouse selection. This is very similar to what text editors like Notepad++ or Eclipse ("Mark Occurrences") offer. However, it allows to have multiple highlighted words in different colors at the same time.

### Installation
* Ensure the file `mark-occurrences.el` is located in Emacs load path, if this is not the case, use `add-to-list` in your Emacs initialization file, e.g. to .emacs: `(add-to-list 'load-path /my/dir)`
* Add the following line to your Emacs initialization file: `(require 'mark-occurrences-mode)`

### Basic keys
 * `<double-mouse-1>` (double-click left mouse button) selects the word at click point (Emacs standard), and after a configurable time passed (default: 600 ms) all occurrences of this whole word in the buffer will be highlighted. Repeat this to also highlight other words
 * `<S-C-double-mouse-1>` (Shift + Ctrl. + double left mouse button) selects the word at click point (Emacs standard), in contrast to the simple double click, not only whole words but also occurrences of the selecte part in the buffer will be highlighted
 * `<double-mouse-3>` (double-click left mouse button) removes all hightlights from the buffer again
 
Please read the documentation in the module `mark-occurrences.el` as well as the Emacs documentation of the function `mark-occurrences-mode` for mode details.
