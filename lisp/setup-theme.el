;;; lisp/setup-theme.el --- Sets shapes and colors  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:
;;;

(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; (setq doom-font (font-spec :family "Fira Code" :size 13 :weight 'light)
;;       doom-variable-pitch-font (font-spec :family "iMWritingDuo Nerd Font" :size 13)
;;       doom-symbol-font (font-spec :family "Iosevka"  :size 13))

(setq user-font "Fira Code")

(after! doom-themes
  (setq doom-themes-enable-bold t
        doom-themes-enable-italic t))

(use-package! tao-theme)

(setq modus-themes-mode-line '(borderless)
      modus-themes-bold-constructs t
      modus-themes-italic-constructs t
      modus-themes-fringes 'subtle
      modus-themes-tabs-accented t
      modus-themes-paren-match '(bold intense)
      modus-themes-prompts '(bold intense)
      modus-themes-completions
      '((matches . (extrabold))
        (selection . (semibold italic text-also)))
      modus-themes-org-blocks 'gray-background
      modus-themes-scale-headings t
      modus-themes-region '(bg-only)
      modus-themes-headings
      '((1 . (rainbow overline background 1.4))
        (2 . (rainbow background 1.3))
        (3 . (rainbow bold 1.2)) c
        (t . (semilight 1.1))))

(defun my/apply-theme (appearance)
  "Load theme, taking current system APPEARANCE into consideration."
  (mapc #'disable-theme custom-enabled-themes)
  (pcase appearance
    ;;('light (load-theme 'doom-acario-light) t)
    ('light (load-theme 'modus-operandi :no-confirm) t)
    ;;('dark (load-theme 'modus-vivendi :no-confirm) t)
    ('dark (load-theme 'doom-opera :no-confirm) t)))

;;Light for the day
(run-at-time "07:15" (* 60 60 24)
             (lambda ()
               (my/apply-theme 'light)))

;; Dark for the night
(run-at-time "18:00" (* 60 60 24)
             (lambda ()
               (my/apply-theme 'dark)))

(set-default 'cursor-type  '(bar . 2))
(blink-cursor-mode 1)

;; Line spacing, can be 0 for code and 1 or 2 for text
(setq-default line-spacing 0)

;; Underline line at descent position, not baseline position
(setq x-underline-at-descent-line t)

;;(setq display-line-numbers-minor-tick 10)

(setq user-font-weight
      (cond
       ((string= user-font "Droid Sans Mono") 'medium)
       (t 'normal))
      )

;; calculate the font size based on display-pixel-height
(setq resolution-factor (eval (/ (display-pixel-height) 1080.0)))
(setq doom-font (font-spec :family user-font :weight user-font-weight :size (eval (round (* 18 resolution-factor))))
      doom-big-font (font-spec :family user-font :weight user-font-weight :size (eval (round (* 22 resolution-factor))))
      doom-variable-pitch-font (font-spec :family user-font :weight user-font-weight :size (eval (round (* 16 resolution-factor))))
      doom-modeline-height (eval (round (* 28 resolution-factor))))
(setq doom-font-increment 1)


(after! doom-modeline
  (setq
   doom-modeline-battery t
   doom-modeline-buffer-file-name-style 'truncate-with-project
   doom-modeline-display-misc-in-all-mode-lines t
   doom-modeline-enable-word-count t
   doom-modeline-hud t
   doom-modeline-time t
   doom-modeline-time-icon nil
   doom-modeline-window-width-limit (- fill-column 10)
   inhibit-compacting-font-caches t))

(setq display-time-format "%I:%M"
      display-time-default-load-average nil)
(display-time-mode t)
(display-battery-mode t)

(custom-set-faces!
  '(font-lock-comment-face :slant italic :family "Courier New")
  '(font-lock-keyword-face :slant italic :family "Courier New")
  '(org-drawer :height 0.9 :slant italic :family "Courier New")
  '(org-meta-line :height 0.9 :slant italic :family "Courier New")
  '(org-table :height 0.9 :family "Courier New")
  '(org-block :height 0.9 :family "Courier New")
  '(org-code  :height 0.9 :family "Courier New")

  (custom-set-faces!
    '(outline-1 :height 1.2 :family "Roboto Mono" :weight light)
    '(outline-2 :height 1.1 :family "Roboto Mono" :weight light)
    '(outline-3 :height 1.0 :family "Roboto Mono" :weight light)
    '(org-document-title :family "Roboto Mono" :height 1.2 :weight light :underline nil))

  (font-lock-add-keywords 'org-mode
                          '(("^\\(?:[  ]*\\)\\(?:[-+]\\|[ ]+\\*\\|\\(?:[0-9]+\\|[A-Za-z]\\)[.)]\\)?[ ]+"
                             . 'fixed-pitch)))
  (font-lock-add-keywords 'org-mode '(("(\\?)" . 'error)))
  )

;; Add frame borders and window dividers
(modify-all-frames-parameters
 '((right-divider-width . 20)
   (internal-border-width . 20)))
(dolist (face '(window-divider
                window-divider-first-pixel
                window-divider-last-pixel))
  (face-spec-reset-face face)
  (set-face-foreground face (face-attribute 'default :background)))

(set-face-background 'fringe (face-attribute 'default :background))


(custom-set-faces! '((corfu-popupinfo) :height 0.8))

(add-hook 'text-mode-hook (lambda () (hl-line-mode -1)))

(use-package! mixed-pitch
  :hook ((org-mode      . mixed-pitch-mode)
         (org-roam-mode . mixed-pitch-mode)
         (LaTeX-mode    . mixed-pitch-mode))
  :config
  (pushnew! mixed-pitch-fixed-pitch-faces
            'warning
            'org-drawer 'org-cite-key 'org-list-dt 'org-hide
            'corfu-default 'font-latex-math-face)
  (setq mixed-pitch-set-height t))

(setq +zen-text-scale 1.1
      writeroom-width 50
 ;; writeroom-mode-line t
      writeroom-extra-line-spacing 0.2)


(defun ash/pretty ()
  "Some enhancements for Org."
  (require 'typopunct)
  (typopunct-change-language 'spanish)
  (typopunct-mode 1)
  (display-line-numbers-mode -1)
  ;;(prettify-symbols-mode t)
  (+org-pretty-mode 1)
  (doom-themes-org-config)
  (+zen/toggle 1)
  (add-to-list 'typopunct-language-alist
               `(spanish ,(decode-char 'ucs #xAB)
                 ,(decode-char 'ucs #xBB)
                 ,(decode-char 'ucs #x201C)
                 ,(decode-char 'ucs #x201D)))

  (setq-default typopunct-buffer-language 'spanish))

;; (ash/pretty)
(add-hook! 'org-mode-hook :append #'ash/pretty)


## https://sachachua.com/dotemacs/index.html#face-text
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


(provide 'setup-theme)
;;; setup-theme.el ends here
