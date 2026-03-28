;;; $DOOMDIR/packages.el -*- no-byte-compile: t; -*-

(unpin! org)
(unpin! org-roam)

(package! org-roam-ui
  :recipe (:host github
           :repo "org-roam/org-roam-ui"
           :files ("*.el" "out")))

(package! org-modern)
(package! citar-org-roam)
(package! ox-hugo)

(package! org-cv
  :recipe (:local-repo "lisp/org-cv"))
(package! ox-gfm)
(package! org-pandoc-import
  :recipe (:host github
           :repo "tecosaur/org-pandoc-import"
           :files ("*.el" "filters" "preprocessors")))
(package! org-fragtog)
(package! org-appear
  :recipe (:host github :repo "awth13/org-appear"))
(package! org-transclusion
  :recipe (:host github
           :repo "nobiot/org-transclusion"
           :branch "main"
           :files ("*.el")))
(package! org-pandoc-import
  :recipe (:host github
           :repo "tecosaur/org-pandoc-import"
           :files ("*.el" "filters" "preprocessors")))
(package! ob-mermaid)

(package! websocket)
(package! simple-httpd)

(package! ov)

(package! iedit)

(package! pcre2el)
(package! visual-regexp-steroids)

(package! mexican-holidays)

(package! all-the-icons
  :recipe (:host github
           :repo "domtronn/all-the-icons.el"))

(package! fzf
  :recipe (:host github
           :repo "bling/fzf.el"))

(package! backup-walker
  :recipe (:host github
           :repo "lewang/backup-walker"))

(package! alabaster-themes
  :recipe (:host github
           :repo "vedang/alabaster-themes"))
(package! nano
  :recipe (:host github
           :repo "rougier/nano-emacs"))

(package! colorful-mode)

(package! smart-cursor-color
  :recipe (:host github
           :repo "7696122/smart-cursor-color"))

(package! format-all)

(package! imenu-list
  :recipe (:host github :repo "bmag/imenu-list"))

;; SVG tags, progress bars & icons
(package! svg-lib
  :recipe (:host github :repo "rougier/svg-lib"))

;; Replace keywords with SVG tags
(package! svg-tag-mode
  :recipe (:host github :repo "rougier/svg-tag-mode"))

(package! monkeytype)

(package! substitute)

(package! wgrep)

(package! auto-save-async
  :recipe (:host github
           :repo "ROCKTAKEY/auto-save-async"))

(package! scimax-ob-flycheck
  :recipe (:host github
           :repo "jkitchin/scimax"
           :branch "master"
           :files ("scimax-ob-flycheck.el")))
