;;; $DOOMDIR/packages.el -*- no-byte-compile: t; -*-


;; (package! org :recipe
;;   (:host nil :repo "https://git.tecosaur.net/mirrors/org-mode.git" :remote "mirror" :fork
;;          (:host nil :repo "https://git.tecosaur.net/tec/org-mode.git" :branch "dev" :remote "tecosaur")
;;          :files
;;          (:defaults "etc")
;;          :build t :pre-build
;;          (with-temp-file "org-version.el"
;;            (require 'lisp-mnt)
;;            (let
;;                ((version
;;                  (with-temp-buffer
;;                    (insert-file-contents "lisp/org.el")
;;                    (lm-header "version")))
;;                 (git-version
;;                  (string-trim
;;                   (with-temp-buffer
;;                     (call-process "git" nil t nil "rev-parse" "--short" "HEAD")
;;                     (buffer-string)))))
;;              (insert
;;               (format "(defun org-release () \"The release version of Org.\" %S)\n" version)
;;               (format "(defun org-git-version () \"The truncate git commit hash of Org mode.\" %S)\n" git-version)
;;               "(provide 'org-version)\n"))))
;;   :pin nil)

;; (unpin! org)

(package! websocket)
(package! simple-httpd)

(package! org-roam-ui
  :recipe (:host github
           :repo "org-roam/org-roam-ui"
           :files ("*.el" "out")))

;;(unpin! use-package)

;; (package! kaocha-runner)

;; (unpin! emacsql-sqlite3)
;; (package! emacsql-sqlite3)
;; (package! emacsql :pin "491105a")

(package! spacemacs-theme)

(package! ov)

(package! lsp-python-ms)

(package! smart-cursor-color
  :recipe (:host github
           :repo "7696122/smart-cursor-color"))

;;(package! howm)

(package! org-modern)

;; ;; (unpin! modus-themes)
;; (package! modus-themes
;;   :recipe (:host github
;;            :repo protesilaos/modus-themes))


;; (package! tao-theme)

;; (package! modus-themes)

;; (package! ef-themes)

;; (unpin! org)
;; (unpin! org-roam)
;;
;;(package! calibre)

;; (package! lambda-themes
;;   :recipe (:host github
;;            :repo "lambda-emacs/lambda-themes"))

(package! pcre2el)
(package! visual-regexp-steroids)

(package! org-cv
  :recipe (:local-repo "lisp/org-cv"))

;; (package! org-cv
;;   :recipe (:host github
;;            :repo "Titan-C/org-cv"))

;; (package! org-ref)

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


(package! lambda-themes
  :recipe (:host github
           :repo "lambda-emacs/lambda-themes"))

(package! nano
  :recipe (:host github
           :repo "rougier/nano-emacs"))

;; (package! subed
;;   :recipe (:host github
;;            :repo "sachac/subed"))


;; (package! subed-record
;;   :recipe (:host github
;;            :repo "sachac/subed-record"))

;; (package! subed-waveform
;;   :recipe (:host github
;;            :repo "sachac/subed-waveform"))

;; (package! compile-media
;;   :recipe (:host github
;;            :repo "sachac/compile-media"))

(package! mpv
  :recipe (:host github
           :repo "kljohann/mpv.el"))

(package! book-mode
  :recipe (:host github
           :repo "rougier/book-mode"))

(package! ts)

;; (package! plz.el
;;   :recipe (:host github
;;            :repo "alphapapa/plz.el"))

(package! ox-gfm)

(package! org-pandoc-import
  :recipe (:host github
           :repo "tecosaur/org-pandoc-import"
           :files ("*.el" "filters" "preprocessors")))


(package! ocp-indent)
;; (package! solaire-mode :disable t)

(package! iedit)

(package! org-fragtog)

(package! org-appear
  :recipe (:host github :repo "awth13/org-appear"))

(package! org-transclusion
  :recipe (:host github
           :repo "nobiot/org-transclusion"
           :branch "main"
           :files ("*.el")))

;; (package! go-translate)

;; (package! dirvish)

;; (package! no-littering
;;   :recipe (:host github
;;            :repo "emacscollective/no-littering"
;;            ;; :files ("*.el")
;;            ))

(package! format-all)


;;(package! vlf
;;  :recipe (:host github :repo "m00natic/vlfi" :files ("*.el")))

(package! tao-theme
  :recipe (:host github :repo "11111000000/tao-theme-emacs" :files ("*.el")))

(package! alabaster-themes
  :recipe (:host github
           :repo "vedang/alabaster-themes"))

(package! imenu-list
  :recipe (:host github :repo "bmag/imenu-list"))


;; SVG tags, progress bars & icons
(package! svg-lib
  :recipe (:host github :repo "rougier/svg-lib"))

;; Replace keywords with SVG tags
(package! svg-tag-mode
  :recipe (:host github :repo "rougier/svg-tag-mode"))

(package! colorful-mode)

;; (package! eat
;;   :recipe (:host codeberg
;;            :repo "akib/emacs-eat"
;;            :files ("*.el" ("term" "term/*.el") "*.texi"
;;                    "*.ti" ("terminfo/e" "terminfo/e/*")
;;                    ("terminfo/65" "terminfo/65/*")
;;                    ("integration" "integration/*")
;;                    (:exclude ".dir-locals.el" "*-tests.el"))))

;; (package! monkeytype)

(package! substitute)

(package! wgrep)

(package! auto-save-async
  :recipe (:host github
           :repo "ROCKTAKEY/auto-save-async"))

;; (package! golden
;;   :recipe (:host nil
;;            :repo "https://git.sr.ht/~wklew/golden"
;;            :files ("*.el")))

(package! ob-mermaid)
;;(package! treesit-auto)

;; (package! no-littering)
;; (package! julia-ts-mode
;;   :recipe (:host github
;;            :repo "ronisbr/julia-ts-mode"))


;; (package! julia-formatter
;;   :recipe (:host codeberg :repo "FelipeLema/julia-formatter.el"
;;            :files ( "julia-formatter.el" ;; main script executed by Emacs
;;                     "toml-respects-json.el" ;; script to parse format config toml files
;;                     "formatter_service.jl" ;; script executed by Julia
;;                     "Manifest.toml" "Project.toml" ;; project files
;;                     )))

(package! citar-org-roam)

(package! scimax-ob-flycheck
  :recipe (:host github
           :repo "jkitchin/scimax"
           :branch "master"
           :files ("scimax-ob-flycheck.el")))

 ;; (package! gptel)
;; (package! elysium)
