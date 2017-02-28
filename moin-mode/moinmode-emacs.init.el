
;; Default-Verzeichnis für Module
(defconst OUTSHINE_DIR "C:/Users/Jens/AppData/Roaming/.emacs.d/elpa/outshine-20161024.2158/")
(defconst OUTORG_DIR "C:/Users/Jens/AppData/Roaming/.emacs.d/elpa/outorg-20160327.132/")
(add-to-list 'load-path OUTSHINE_DIR)
(add-to-list 'load-path OUTORG_DIR)

(defconst MODULES_DIR "E:/Programmieren/Planung/")

(defconst OWN_MODULES_DIR (concat MODULES_DIR "ownModules/"))
(add-to-list 'load-path OWN_MODULES_DIR)

(require 'moin-mode)
(add-to-list 'auto-mode-alist '(".*test\\'" . moin-mode))

(setq inhibit-startup-screen t)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(initial-frame-alist (quote ((fullscreen . maximized)))))
