;;; lisp/setup-theme-nano.el --- Sets shapes and colors  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:
;;;


(setq nano-font-size 12)
;; (setq nano-font-family-monospaced "Roboto Mono")
(setq nano-font-family-monospaced "iMWritingMono Nerd Font Mono")
(setq nano-font-family-proportional "Iosevka Aile")
(use-package! nano)

;;  Default layout (optional)
(require 'nano-layout)

;; Theme
(require 'nano-base-colors)
(require 'nano-faces)
(nano-faces)

;; (require 'nano-theme)
(require 'nano-dark-theme)
(require 'nano-light-theme)

;;(require 'nano-modeline)
;;(require 'nano-help)
;; (require 'nano-calendar)
;; (require 'nano-agenda)
;; (require 'nano-compact)

(defun my/apply-theme (appearance)
  "Load theme, taking current system APPEARANCE into consideration."
  (mapc #'disable-theme custom-enabled-themes)
  (pcase appearance
    ('light (nano-light) t)
    ('dark (nano-dark) t))
     ;; (call-interactively 'nano-refresh-theme)
  )


;;Light for the day
(run-at-time "07:15" (* 60 60 24)
             (lambda ()
               (my/apply-theme 'light)))

;; Dark for the night
(run-at-time "18:00" (* 60 60 24)
             (lambda ()
               (my/apply-theme 'dark)))

;;(my/apply-theme 'dark)

(setq +zen-text-scale 0.9
      writeroom-width 65
      ;; writeroom-mode-line t
      writeroom-extra-line-spacing 0.2)

(defun ash/pretty ()
  "Some enhancements for Org."
  (require 'typopunct)
  (typopunct-change-language 'spanish)
  (typopunct-mode 1)
  (+zen/toggle 1)
  (add-to-list 'typopunct-language-alist
               `(spanish ,(decode-char 'ucs #xAB)
                 ,(decode-char 'ucs #xBB)
                 ,(decode-char 'ucs #x201C)
                 ,(decode-char 'ucs #x201D)))
  (setq-default typopunct-buffer-language 'spanish))

;; (ash/pretty)
(add-hook! 'org-mode-hook :append #'ash/pretty)



;;; https://sachachua.com/dotemacs/index.html#face-text
(defun my-add-face-text-property (start end attribute value)
  (interactive
   (let ((attribute (intern
                     (completing-read
                      "Attribute: "
                      (mapcar (lambda (o) (symbol-name (car o)))
                              face-attribute-name-alist)))))
     (list (point)
           (mark)
           attribute
           (read-face-attribute '(()) attribute))))
  (add-face-text-property start end (list attribute value)))

(defun my-face-text-larger (start end)
  (interactive "r")
  (add-face-text-property
   start end
   (list :height (floor (+ 50 (car (alist-get :height (get-text-property start 'face) '(100))))))))

(defun my-face-text-smaller (start end)
  (interactive "r")
  (add-face-text-property
   start end
   (list :height (floor (- (car (alist-get :height (get-text-property start 'face) '(100))) 50)))))

(defvar-keymap my-face-text-property-mode-map
  "M-o p" #'my-add-face-text-property
  "M-o +" #'my-face-text-larger
  "M-o -" #'my-face-text-smaller)

(define-minor-mode my-face-text-property-mode
  "Make it easy to modify face properties."
  :init-value nil
  (repeat-mode 1))

(defvar-keymap my-face-text-property-mode-repeat-map
  :repeat t
  "+" #'my-face-text-larger
  "-" #'my-face-text-smaller)

(dolist (cmd '(my-face-text-larger my-face-text-smaller))
  (put cmd 'repeat-map 'my-face-text-property-mode-repeat-map))

(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; ;; No scroll bars
(if (fboundp 'scroll-bar-mode) (set-scroll-bar-mode nil))

;; ;; No toolbar
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))

;; ;; No menu
(if (fboundp menu-bar-mode) (menu-bar-mode -1))


;; (defun nano-theme-set-spaceduck ()
;;   (setq frame-background-mode 'dark)
;;   (setq nano-color-foreground "#ecf0c1")
;;   (setq nano-color-background "#0f111b")
;;   (setq nano-color-highlight  "#1b1c36")
;;   (setq nano-color-critical   "#e33400")
;;   (setq nano-color-salient    "#00a4cc")
;;   (setq nano-color-strong     "#e39400")
;;   (setq nano-color-popout     "#f2ce00")
;;   (setq nano-color-subtle     "#7a5ccc")
;;   (setq nano-color-faded      "#b3a1e6"))

;; (nano-theme-set-spaceduck)


;;(require 'nano-defaults)

;; ;; Initial buffer
;; (setq initial-buffer-choice nil)

;; ;; No frame title
(setq frame-title-format nil)

;; ;; No file dialog
(setq use-file-dialog nil)

;; ;; No dialog box
(setq use-dialog-box nil)

;; ;; No popup windows
;; (setq pop-up-windows nil)

;; ;; No empty line indicators
;; (setq indicate-empty-lines nil)

;; ;; No cursor in inactive windows
(setq cursor-in-non-selected-windows nil)

;; ;; Text mode is initial mode
;; (setq initial-major-mode 'text-mode)

;; ;; Text mode is default major mode
;; (setq default-major-mode 'text-mode)

;; ;; Moderate font lock
(setq font-lock-maximum-decoration nil)

;; ;; No limit on font lock
(setq font-lock-maximum-size nil)

;; ;; No line break space points
;; (setq auto-fill-mode nil)

;; ;; Fill column at 80
(setq fill-column 120)

;; ;; No confirmation for visiting non-existent files
(setq confirm-nonexistent-file-or-buffer nil)

;; ;; Completion style, see
;; ;; gnu.org/software/emacs/manual/html_node/emacs/Completion-Styles.html
;; ;;(setq completion-styles '(basic substring))

;; ;; Use RET to open org-mode links, including those in quick-help.org
(setq org-return-follows-link t)

;; ;; Mouse active in terminal
(unless (display-graphic-p)
  (xterm-mouse-mode 1)
  (global-set-key (kbd "<mouse-4>") 'scroll-down-line)
  (global-set-key (kbd "<mouse-5>") 'scroll-up-line))


;; ;; y/n for  answering yes/no questions
(fset 'yes-or-no-p 'y-or-n-p)

;; ;; No tabs
(setq-default indent-tabs-mode nil)

;; ;; Tab.space equivalence
(setq-default tab-width 4)

;; ;; Size of temporary buffers
(temp-buffer-resize-mode)
(setq temp-buffer-max-height 8)

;; ;; Minimum window height
(setq window-min-height 1)

;; ;; Buffer encoding
(prefer-coding-system       'utf-8)
(set-default-coding-systems 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(set-language-environment   'utf-8)

;; ;; Unique buffer names
(require 'uniquify)
(setq uniquify-buffer-name-style 'reverse
      uniquify-separator " • "
      uniquify-after-kill-buffer-p t
      uniquify-ignore-buffers-re "^\\*")

;; ;; Default shell in term
;; (unless
;;     (or (eq system-type 'windows-nt)
;;         (not (file-exists-p "/bin/zsh")))
;;   (setq-default shell-file-name "/bin/zsh")
;;   (setq explicit-shell-file-name "/bin/zsh"))

;; ;; Kill term buffer when exiting
;; (defadvice term-sentinel (around my-advice-term-sentinel (proc msg))
;;   (if (memq (process-status proc) '(signal exit))
;;       (let ((buffer (process-buffer proc)))
;;         ad-do-it
;;         (kill-buffer buffer))
;;     ad-do-it))
;; (ad-activate 'term-sentinel)


(provide 'setup-theme-nano)
;;; setup-theme-nano.el ends here
