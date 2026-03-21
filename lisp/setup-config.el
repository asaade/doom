;;; lisp/setup-config.el --- Main configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;; ========================================================

(setq time-stamp-active t
      time-stamp-line-limit 10)
(add-hook 'before-save-hook 'time-stamp)
(remove-hook! '(text-mode-hook) #'display-line-numbers-mode)

;; Show fill column line.
;; (add-hook! prog-mode (display-fill-column-indicator-mode t))


;;; ========================================================
;;; https://sachachua.com/dotemacs/index.html#minibuffer-editing-more-space
;; General Settings
(setq completion-ignore-case t
      confirm-kill-emacs nil
      confirm-kill-processes nil
      global-auto-revert-mode t
      password-cache-expiry nil
      read-buffer-completion-ignore-case t
      use-short-answers t
      visible-bell t
      window-combination-resize t
      x-select-enable-clipboard-manager nil
      x-stretch-cursor t)

(setq dired-vc-rename-file t)

;;; Put Emacs auto-save and backup files to /tmp/ or C:/Temp/
;; (setenv "temporary-file-directory" "/home/asaade/tmp/")
(setq temporary-file-directory "/home/asaade/tmp/")
(defconst emacs-tmp-dir (expand-file-name (format "emacs%d" (user-uid)) temporary-file-directory))

;;; Lockfiles unfortunately cause more pain than benefit
(setq create-lockfiles nil)

(make-directory "~/.config/emacs/auto-save-list/" t)
(make-directory "~/.config/emacs/backups" t)

;; Backup and Auto-save Configuration
(setq auto-save-list-file-prefix emacs-tmp-dir
      auto-save-file-name-transforms '((".*" "~/.config/emacs/auto-save-list/" t))
      backup-by-copying t
      ;;backup-directory-alist `((".*" . ,emacs-tmp-dir))
      delete-by-moving-to-trash t
      delete-old-versions -1
      history-delete-duplicates t
      history-length t
      kept-new-versions 10
      kept-old-versions 10
      kill-ring-max 1000
      kill-whole-line t
      recentf-max-saved-items 500
      savehist-additional-variables
      '(kill-ring search-ring regexp-search-ring)
      savehist-mode 1
      savehist-file "~/.config/emacs/savehist"
      savehist-save-minibuffer-history 1
      vc-make-backup-files t
      version-control t)

(setq backup-directory-alist '(("\\.env$" . nil)
                               ("." . "~/.config/emacs/backups")))
(with-eval-after-load 'tramp
  (setq tramp-backup-directory-alist nil))

(setq emojify-display-style 'unicode)


(use-package! proced
  :defer t
  :custom
  (proced-enable-color-flag t)
  (proced-tree-flag t))


;;;###autoload
(defun my-embark-which-key-action-indicator (map target)
  "Helper function to display the 'whichey' help buffer for embark."
  (which-key--show-keymap "Embark" map nil nil 'no-paging)
  #'which-key--hide-popup-ignore-command)

(setq embark-action-indicator #'my-embark-which-key-action-indicator
      embark-become-indicator embark-action-indicator)

;; ;; Emacs 28: Hide commands in M-x which do not work in the current mode.
;; ;; Vertico commands are hidden in normal buffers.
(setq read-extended-command-predicate
      #'command-completion-default-include-p)


(defun ash/save-ignore-errors ()
  (ignore-errors
    (save-some-buffers)))

(add-hook 'kill-emacs-hook 'ash/save-ignore-errors)

;; Offer to create parent directories if they do not exist
;; http://iqbalansari.github.io/blog/2014/12/07/automatically-create-parent-directories-on-visiting-a-new-file-in-emacs/
(defun ash/my-create-non-existent-directory ()
  (let ((parent-directory (file-name-directory buffer-file-name)))
    (when (and (not (file-exists-p parent-directory))
               (y-or-n-p (format "Directory `%s' does not exist! Create it?" parent-directory)))
      (make-directory parent-directory t))))

(add-to-list 'find-file-not-found-functions 'ash/my-create-non-existent-directory)

;; Stolen from https://emacs.stackexchange.com/a/13096/8964
(defun ash/reload-dir-locals-for-current-buffer ()
  "Reload dir locals for the current buffer."
  (interactive)
  (let ((enable-local-variables :all))
    (hack-dir-local-variables-non-file-buffer)))

(after! lsp-python-ms
  (set-lsp-priority! 'mspyls 1))


(after! web-mode
  (setq web-mode-js-indent-offset 4
        web-mode-markup-indent-offset 4
        web-mode-css-indent-offset 4
        web-mode-code-indent-offset 4
        web-mode-enable-auto-pairing t
        web-mode-enable-css-colorization t))

(after! corfu
  (setq corfu-auto-delay 0.5))


;; https://sachachua.com/dotemacs/index.html#about-this-file-backups-obscure-emacs-package-appreciation-backup-walker
(use-package backup-walker
  :commands backup-walker-start
  :init
  (defalias 'string-to-int 'string-to-number)  ; removed in 26.1
  (defalias 'display-buffer-other-window 'display-buffer))

(defun my-backup-walker-refresh ()
  (let* ((index (cdr (assq :index backup-walker-data-alist)))
         (suffixes (cdr (assq :backup-suffix-list backup-walker-data-alist)))
         (prefix (cdr (assq :backup-prefix backup-walker-data-alist)))
         (right-file (concat prefix (nth index suffixes)))
         (right-version (format "%i" (backup-walker-get-version right-file)))
         diff-buff left-file left-version)
    (if (eq index 0)
        (setq left-file (cdr (assq :original-file backup-walker-data-alist))
              left-version "orig")
      (setq left-file (concat prefix (nth (1- index) suffixes))
            left-version (format "%i" (backup-walker-get-version left-file))))
    ;; we change this to go the other way here
    (setq diff-buf (diff-no-select right-file left-file nil 'noasync))
    (setq buffer-read-only nil)
    (delete-region (point-min) (point-max))
    (insert-buffer diff-buf)
    (set-buffer-modified-p nil)
    (setq buffer-read-only t)
    (force-mode-line-update)
    (setq header-line-format
          (concat (format "{{ ~%s~ → ~%s~ }} "
                          (propertize left-version 'face 'font-lock-variable-name-face)
                          (propertize right-version 'face 'font-lock-variable-name-face))
                  (if (nth (1+ index) suffixes)
                      (concat (propertize "<p>" 'face 'italic)
                              " ~"
                              (propertize (int-to-string
                                           (backup-walker-get-version (nth (1+ index) suffixes)))
                                          'face 'font-lock-keyword-face)
                              "~ ")
                    "")
                  (if (eq index 0)
                      ""
                    (concat (propertize "<n>" 'face 'italic)
                            " ~"
                            (propertize (int-to-string (backup-walker-get-version (nth (1- index) suffixes)))
                                        'face 'font-lock-keyword-face)
                            "~ "))
                  (propertize "<return>" 'face 'italic)
                  " open ~"
                  (propertize (propertize (int-to-string (backup-walker-get-version right-file))
                                          'face 'font-lock-keyword-face))
                  "~"))
    (kill-buffer diff-buf)))
(with-eval-after-load 'backup-walker
  (advice-add 'backup-walker-refresh :override #'my-backup-walker-refresh))


(provide 'setup-config)
;;; setup-config.el ends here
