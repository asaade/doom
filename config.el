;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(defvar my/init-start-time (current-time) "Time when init.el was started")
(defvar my/section-start-time (current-time) "Time when section was started")
(defun my/report-time (section)
  (message "%-36s %.2fs"
           (concat section " " "section time: ")
           (float-time (time-subtract (current-time) my/section-start-time))))
(message "---------------------------------------------------------------")

;;; For performance
(setq read-process-output-max (* 1024 1024)) ;; 1mb

(setq comp-deferred-compilation t)
(setq comp-async-jobs-number 6)

;; Version control optimization
(setq vc-handled-backends '(Git))

;; Do not load outdated byte code files.
(setq load-prefer-newer t)

;; Increase for better lsp performance.
(setq read-process-output-max (* 3 1024 1024)) ;; 3mb

;; Avoid Lisp nesting exceeding
(setq max-lisp-eval-depth 10000)

(unless (daemonp)
  (advice-add #'tty-run-terminal-initialization :override #'ignore)
  (add-hook 'window-setup-hook
            (defun doom-init-tty-h ()
              (advice-remove #'tty-run-terminal-initialization #'ignore)
              (tty-run-terminal-initialization (selected-frame) nil t))))

(after! auth-source
  (setq auth-sources (nreverse auth-sources)))

;; Personal Information
(setq user-full-name "Antonio Saade"
      user-mail-address "xxxx@gmail.com")

(add-load-path! "~/.config/doom/lisp")

;; Directory Setup
(setq dropbox-directory "~/Dropbox"
      org-directory "~/Dropbox/org"
      org-roam-directory "~/Dropbox/org/roam"
      org-roam-dailies-directory "~/Dropbox/org/roam/journal/")

(make-directory "/home/asaade/tmp/" t)
(setenv "TMPDIR" "/home/asaade/tmp/")
(setq temporary-file-directory "/home/asaade/tmp/")

;; Custom File Handling
(setq-default custom-file (expand-file-name ".custom.el" "~/.config/doom/"))
(when (file-exists-p custom-file)
  (load custom-file))

(setq ;; auth-sources '("~/.authinfo.gpg")
 auth-source-cache-expiry nil) ; default is 7200 (2h)

(setq byte-compile-warnings '(cl-functions))

;; Make native compilation silent and prune its cache.
(when (native-comp-available-p)
  (setq native-comp-async-report-warnings-errors 'silent) ; Emacs 28 with native compilation
  (setq native-compile-prune-cache t)) ; Emacs 29

;; Enable these
(mapc
 (lambda (command)
   (put command 'disabled nil))
 '(list-timers narrow-to-region narrow-to-page upcase-region downcase-region))

;; And disable these
(mapc
 (lambda (command)
   (put command 'disabled t))
 '(eshell project-eshell overwrite-mode iconify-frame diary))

(load! "./lisp/setup-config")
(load! "./lisp/setup-yas")
(load! "./lisp/setup-theme-modern")
;;(load! "./lisp/setup-theme-nano")
(load! "./lisp/setup-utils")
(load! "./lisp/dired-fixups")
(load! "./lisp/setup-multimedia.el")



(after! dired
  (remove-hook 'dired-mode-hook 'dired-omit-mode)
  (setq dired-listing-switches "-aBhlv --group-directories-first"
        dired-dwim-target t
        dired-recursive-copies (quote always)
        dired-recursive-deletes (quote always)
        dired-omit-extensions nil
        ;; Directly edit permisison bits!
        wdired-allow-to-change-permissions t))



(with-eval-after-load 'dired
  (add-hook! 'dired-mode-hook 'context-menu-mode))

;; (defun dino-dired-mode-hook-fn ()
;;   (hl-line-mode 1)
;;   (define-key dired-mode-map (kbd "C-c C-g") #'dino-dired-kill-new-file-contents)
;;   (define-key dired-mode-map (kbd "C-c C-c") #'dino-dired-copy-file-to-dir-in-other-window)
;;   (define-key dired-mode-map (kbd "C-c C-m") #'dino-dired-move-file-to-dir-in-other-window)
;;   (define-key dired-mode-map (kbd "C-c m")   #'magit-status)
;;   (define-key dired-mode-map (kbd "C-x m")   #'magit-status)
;;   ;; converse of i (dired-maybe-insert-subdir)
;;   (define-key dired-mode-map (kbd "K")  #'dired-kill-subdir)
;;   (define-key dired-mode-map (kbd "F")  #'dino-dired-do-find)
;;   (define-key dired-mode-map (kbd "s")  #'dino-dired-sort-cycle)
;;   (dino-dired-sort-cycle "t") ;; by default, sort by time
;;   (turn-on-auto-revert-mode))


(after! org
  (load! "./lisp/setup-org"))

(smart-cursor-color-mode +1)

(define-key (current-global-map) (kbd "C-;") nil)

(map! "<escape>" #'keyboard-escape-quit)
(map! "C-+"      #'text-scale-increase)
(map! "C--"      #'text-scale-decrease)
(map! "C-c C-n"  #'ash/cleanup-buffer)
(map! "C-c P"    #'ash/copy-file-name-to-clipboard)
(map! "C-c r"    #'consult-ripgrep)
(map! "C-g"      #'prot/keyboard-quit-dwim)
(map! "C-s"      #'+default/search-buffer)
(map! "C-x k"    #'kill-current-buffer)
(map! "C-x C-j"  #'ash/kill-other-buffers)
(map! "C-x j"    #'rst-join-paragraph)
(map! "M-B"      #'goto-last-modification)
(map! "C-;"      #'iedit-mode)

;; start a httpd-server in current directory
(defun httpd-start-here (directory port)
  (interactive (list (read-directory-name "Root directory: " default-directory nil t)
                     (read-number "Port: " 8017)))
  (setq httpd-root directory)
  (setq httpd-port port)
  (httpd-start)
  (browse-url (concat "http://localhost:" (number-to-string port) "/")))


(setq calendar-week-start-day 1
      calendar-day-name-array ["domingo" "lunes" "martes" "miércoles"
                               "jueves" "viernes" "sábado"]
      calendar-month-abbrev-array ["dom" "lun" "mar" "mié"
                                   "jue" "vie" "sáb"]
      calendar-month-name-array ["enero" "febrero" "marzo" "abril"
                                 "mayo" "junio" "julio" "agosto"
                                 "septiembre" "octubre" "noviembre"
                                 "diciembre"]
      calendar-month-abbrev-array ["ene" "feb" "mar" "abr"
                                   "may" "jun" "jul" "ago"
                                   "sep" "oct" "nov"
                                   "dic"])

;;;; World clock (M-x world-clock)
(use-package! time
  :defer t
  :commands (world-clock)
  :config
  (setq world-clock-list t)
  (setq zoneinfo-style-world-list ; M-x shell RET timedatectl list-timezones
        '(("America/Los_Angeles" "San Diego")
          ("America/New_York" "New York")
          ("America/Toronto" "Toronto")
          ("America/Vancouver" "Vancouver")
          ("America/Santiago" "Santiago")
          ("Europe/London" "London")
          ("Europe/Paris" "Paris")
          ("Europe/Amsterdam" "Rotterdam")
          ("UTC" "UTC")
          ("Europe/Lisbon" "Lisbon")
          ("Europe/Brussels" "Brussels")
          ("Asia/Jerusalem" "Belén")
          ("Asia/Calcutta" "Bangalore")
          ("Asia/Tokyo" "Tokyo")
          ("Australia/Sydney" "Sydney")))

  ;; All of the following variables are for Emacs 28
  (setq world-clock-list t)
  (setq world-clock-time-format "%R %z (%Z)     %A %d %B")
  (setq world-clock-buffer-name "*world-clock*") ; Placement handled by `display-buffer-alist'
  (setq world-clock-timer-enable t)
  (setq world-clock-timer-second 60)
  )

(map! "M-n M-n" (cmd! (insert "\u200B")))

(defun delete-current-line ()
  "Delete (not kill) the current line."
  (interactive)
  (save-excursion
    (delete-region
     (progn (forward-visible-line 0) (point))
     (progn (forward-visible-line 1) (point)))))

(setq lsp-julia-package-dir nil
      lsp-julia-default-environment "~/.julia/environments/v1.12")

(after! company
  (setq company-idle-delay 0.5
        company-selection-wrap-around t
        company-require-match 'never
        company-dabbrev-downcase nil
        company-dabbrev-ignore-case t
        company-dabbrev-other-buffers nil
        company-tooltip-limit 5
        company-tooltip-minimum-width 40
        company-tooltip-align-annotations t
        company-transformers '(company-sort-by-occurrence))
  (set-company-backend!
   '(text-mode
     markdown-mode
     gfm-mode)
   '(:separate
     company-files))
  )

(use-package! ocp-indent)

(use-package! pyvenv
  :config
  (setq pyvenv-workon "emacs")  ; Default venv
  (pyvenv-workon pyvenv-workon)

  (when (fboundp 'pyvenv-track-virtualenv)
    (fmakunbound 'pyvenv-track-virtualenv))

  (defun pyvenv-track-virtualenv ()
    "Set a virtualenv as specified for the current buffer.

;; This is originally provided by pyvenv, but I've added a couple
;; of features. The most important one is that this invokes lsp
;; /after/ all the pyvenv activate logic has been done, which means
;; lsp can properly jump to definitions."
    (when (string= major-mode "python-mode")
      (cond
       (pyvenv-activate
        (when (and (not (equal (file-name-as-directory pyvenv-activate)
                               pyvenv-virtual-env))
                   (or (not pyvenv-tracking-ask-before-change)
                       (y-or-n-p (format "Switch to virtualenv %s (currently %s)"
                                         pyvenv-activate pyvenv-virtual-env))))
          (pyvenv-activate pyvenv-activate)))
       (pyvenv-workon
        (when (and (not (equal pyvenv-workon pyvenv-virtual-env-name))
                   (or (not pyvenv-tracking-ask-before-change)
                       (y-or-n-p (format "Switch to virtualenv %s (currently %s)"
                                         pyvenv-workon pyvenv-virtual-env-name))))
          (message "pyvenv switching from %s to %s" pyvenv-virtual-env-name pyvenv-workon)
          (pyvenv-workon pyvenv-workon))
        ;; lsp needs to run after pyvenv-workon, so we make sure it's running here rather than
        ;; in the python-mode-hook.
        ;; (when (not lsp-mode)
        ;;   (lsp))
        ))))

  (pyvenv-tracking-mode 1))  ; Automatically use pyvenv-workon via dir-locals


;; Language-Specific Settings
(setq inferior-R-args "--no-save --no-restore --quiet"
      inferior-lisp-program "sbcl --dynamic-space-size 8192"
      +python-ipython-repl-args '("-i" "--simple-prompt" "--no-color-info")
      +python-jupyter-repl-args '("--simple-prompt"))


(after! tramp
  ;; (add-to-list 'tramp-backup-directory-alist
  ;;             (cons tramp-file-name-regexp nil))
  (add-to-list 'tramp-connection-properties
               (list (regexp-quote "/scp:saade.me:")
                     "direct-async-process" t))
  (add-to-list 'tramp-connection-properties
               (list (regexp-quote "/scp:4gps:")
                     "direct-async-process" t))

  (setq delete-by-moving-to-trash nil)

  ;; Tips to speed up connections
  (setq tramp-use-scp-direct-remote-copying t
        tramp-verbose 0
        tramp-chunksize 2000
        tramp-use-ssh-controlmaster-options nil
        vc-ignore-dir-regexp
        (format "\\(%s\\)\\|\\(%s\\)"
                vc-ignore-dir-regexp
                tramp-file-name-regexp))
  (setenv "SHELL" "/bin/bash")
  (setq tramp-shell-prompt-pattern "\\(?:^\\|\n\\|\x0d\\)[^]#$%>\n]*#?[]#$%>] *\\(\e\\[[0-9;]*[a-zA-Z] *\\)*")
  (customize-set-variable 'tramp-default-method "scp"))


;; (after! projectile
;;   (setq projectile-project-root-files-bottom-up
;;         (remove ".git" projectile-project-root-files-bottom-up)))

(setq projectile-ignored-projects
      (list "~/" "~/tmp" "/tmp" (expand-file-name "straight/repos" doom-local-dir)))

(defun projectile-ignored-project-function (filepath)
  "Return t if FILEPATH is within any of `projectile-ignored-projects'"
  (or (mapcar (lambda (p) (string-prefix-p p filepath)) projectile-ignored-projects)))

(setq undo-limit 67108864) ; 64mb.
(setq undo-strong-limit 100663296) ; 96mb.
(setq undo-outer-limit 1006632960) ; 960mb.

(my/report-time "System")

(let ((init-time (float-time (time-subtract (current-time) my/init-start-time)))
      (total-time (string-to-number (emacs-init-time "%f"))))

  (message "---------------------------------------------------------------")
  (message "Initialization time:                 %.2fs (+ %.2f system time)"
           init-time (- total-time init-time)))
(message "---------------------------------------------------------------")
