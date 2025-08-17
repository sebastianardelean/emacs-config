(require 'package)

;; -------------------------
;; Package setup
;; -------------------------
(setq package-archives
      '(("melpa" . "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")
        ("gnu" . "https://elpa.gnu.org/packages/")))

;; Initialize the package system
(package-initialize)
(unless package-archive-contents
  (package-refresh-contents))


(unless (package-installed-p 'use-package)
  (package-install 'use-package))

(require 'use-package)
(setq use-package-always-ensure t)

;; -------------------------
;; Global settings
;; -------------------------
(setq-default
 indent-tabs-mode nil
 tab-width 4
 c-default-style "bsd"
 c-basic-offset 4
 backup-by-copying t
 backup-directory-alist '(("." . "~/.emacs.d/backups/"))
 delete-old-versions t
 kept-new-versions 6
 kept-old-versions 2
 version-control t
 TeX-engine 'xetex
 TeX-PDF-mode t
 tab-always-indent t
 menu-bar-mode t
 tool-bar-mode -1
 )



(when (version<= "26.0.50" emacs-version)
  (global-display-line-numbers-mode))



;; -------------------------
;; Themes
;; -------------------------
;;(use-package timu-macos-theme
;;  :config
;;  (setq timu-macos-flavour "dark")
;;  (load-theme 'timu-macos t))

;; -------------------------
;; Programming modes
;; -------------------------
(use-package tree-sitter :defer t)
(use-package tree-sitter-langs :after tree-sitter)


(use-package python-mode :defer t)
(use-package haskell-mode
  :hook ((haskell-mode . turn-on-haskell-doc-mode)
         (haskell-mode . turn-on-haskell-indentation))
  :config
  (add-to-list 'completion-ignored-extensions ".hi"))

(use-package clojure-mode :defer t)
(use-package cider :defer t)


(use-package rust-mode
  :hook (rust-mode . (lambda () (setq indent-tabs-mode nil))))

(use-package verilog-mode :defer t)




(use-package modern-cpp-font-lock :defer t)


(use-package slime
  :commands (slime slime-connect)
  :custom
  (inferior-lisp-program "/usr/bin/sbcl --noinform")
  :config
  (slime-setup))


(use-package simple-httpd
  :ensure )

;; -------------------------
;; Git
;; -------------------------
(use-package magit :commands magit-status)


;; -------------------------
;; Org mode
;; -------------------------
(use-package org-ref :defer t)
(use-package org-roam
    :ensure t
    :init (setq org-roam-v2-ack t)
    :custom
    (org-roam-directory "~/.emacs.d/org-notes")
    (org-roam-completion-everywhere t)
    :bind (("C-c n l" . org-roam-buffer-toggle)
           ("C-c n f" . org-roam-node-find)
           ("C-c n i" . org-roam-node-insert)
           :map org-mode-map
           ("C-M-i"    . completion-at-point))
    :config
    (org-roam-setup))

(use-package plantuml-mode
  :custom
  (org-plantuml-jar-path (expand-file-name "~/.emacs.d/plantuml.jar"))
  :config
  (with-eval-after-load 'org
    (org-babel-do-load-languages
     'org-babel-load-languages
     '((ruby . t) (plantuml . t))))
  (add-hook 'org-babel-after-execute-hook
            (lambda ()
              (when org-inline-image-overlays
                (org-redisplay-inline-images)))))

;; -------------------------
;; File tree
;; -------------------------
(use-package treemacs
  :bind (("M-0"       . treemacs-select-window)
         ("C-x t 1"   . treemacs-delete-other-windows)
         ("C-x t t"   . treemacs)
         ("C-x t d"   . treemacs-select-directory)
         ("C-x t B"   . treemacs-bookmark)
         ("C-x t C-t" . treemacs-find-file)
         ("C-x t M-t" . treemacs-find-tag))
  :config
  (setq treemacs-follow-mode t
        treemacs-follow-after-init t
        treemacs-space-between-root-nodes nil
        treemacs-git-mode 'extended))


;; -------------------------
;; Snippets & autocomplete
;; -------------------------
(use-package yasnippet
  :config (yas-global-mode 1))
(use-package yasnippet-snippets :after yasnippet)

(use-package auto-complete
  :init (ac-config-default)
  :config (global-auto-complete-mode t))

;; -------------------------
;; LaTeX
;; -------------------------
(add-hook 'TeX-mode-hook #'prettify-symbols-mode)
(add-hook 'TeX-mode-hook #'TeX-fold-mode)


;; -------------------------
;; Ctags
;; -------------------------
(setq path-to-ctags "/usr/local/bin/ctags"
      path-to-ctags-out-file "~/.emacs.d/Tags/TAGS")

(defun create-tags (dir-name)
  "Create tags file."
  (interactive "DDirectory: ")
  (shell-command
   (format "%s -f %s -e -R %s"
           path-to-ctags path-to-ctags-out-file (directory-file-name dir-name))))

;; -------------------------
;; RSS
;; -------------------------
(setq elfeed-feeds
      '(("https://feeds.arstechnica.com/arstechnica/index" arstechnica)
        ("https://rss.sciencedirect.com/publication/science/23527110" softwareX)))
(setq url-queue-timeout 30)


