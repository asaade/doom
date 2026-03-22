;;; $DOOMDIR/lisp/setup-theme-modern.el --- Modern, attractive, and functional UI config -*- lexical-binding: t; -*-
;;; Commentary:
;; A completely redesigned aesthetic emphasizing readability, clean UI,
;; and a harmonious blend of modern typography with day/night theme switching.
;;; Code:

;; ---------------------------------------------------------------------------
;; 1. Base UI Settings (Minimalism)
;; ---------------------------------------------------------------------------
(setq default-frame-alist
      (append (list
               '(vertical-scroll-bars . nil)
               '(internal-border-width . 16) ; A nice, modern padded window border
               '(left-fringe    . 16)
               '(right-fringe   . 16)
               '(tool-bar-lines . 0)
               '(menu-bar-lines . 0)
               '(fullscreen . maximized))
              default-frame-alist))

(setq window-divider-default-right-width 2
      window-divider-default-bottom-width 2
      window-divider-default-places 'right-only)
(window-divider-mode 1)

;; Cursor & Line
(set-default 'cursor-type '(bar . 2))
(blink-cursor-mode 1)
(setq-default line-spacing 0.15) ; More breathing room for modern typography
(setq x-underline-at-descent-line t) ; Better underlines
(add-hook 'text-mode-hook (lambda () (hl-line-mode -1))) ; Less distraction in text

;; ---------------------------------------------------------------------------
;; 2. Typography
;; ---------------------------------------------------------------------------
;; We use JetBrains Mono for code (very legible) and Inter for prose.
(setq user-font "JetBrains Mono"
      variable-font "Inter"
      symbols-font "Symbols Nerd Font")

(setq resolution-factor (/ (display-pixel-height) 1080.0))

;; IMPORTANT: Do not hardcode exact fonts in `custom-set-faces!` for things that
;; depend on `doom-font`. We define the core fonts here.
(setq doom-font (font-spec :family user-font :weight 'normal :size (round (* 15 resolution-factor)))
      doom-variable-pitch-font (font-spec :family variable-font :weight 'normal :size (round (* 16 resolution-factor)))
      doom-big-font (font-spec :family user-font :weight 'normal :size (round (* 24 resolution-factor)))
      doom-symbol-font (font-spec :family symbols-font :size (round (* 15 resolution-factor))))

(setq doom-font-increment 1)

;; Variable pitch serif for specific contexts
(defcustom variable-pitch-serif-font (font-spec :family "Merriweather" :size (round (* 16 resolution-factor)))
  "The font face used for `variable-pitch-serif'."
  :group 'basic-faces
  :type '(restricted-sexp :tag "font-spec" :match-alternatives (fontp))
  :set (lambda (symbol value)
         (set-face-attribute 'variable-pitch-serif nil :font value)
         (set-default-toplevel-value symbol value)))

(defface variable-pitch-serif
  '((t (:family "Merriweather")))
  "A variable-pitch face with serifs."
  :group 'basic-faces)

;; ---------------------------------------------------------------------------
;; 3. Themes (Day / Night Auto-Switch)
;; ---------------------------------------------------------------------------
;; We use alabaster (light) and lambda-dark (dark) for a high-contrast,
;; minimal-color approach, reducing cognitive load during coding.

(use-package! alabaster-themes)
(use-package! lambda-themes
  :custom
  (lambda-themes-set-italic-comments t)
  (lambda-themes-set-italic-keywords t)
  (lambda-themes-set-variable-pitch t))

(defun my/apply-modern-theme (appearance)
  "Load a high-contrast, low-color theme, based on system APPEARANCE."
  (mapc #'disable-theme custom-enabled-themes)
  (pcase appearance
    ('light (load-theme 'alabaster-themes-light :no-confirm) t)
    ('dark  (load-theme 'lambda-dark :no-confirm) t)))

;; Switch at specific times
(run-at-time "07:00" (* 60 60 24) (lambda () (my/apply-modern-theme 'light)))
(run-at-time "18:30" (* 60 60 24) (lambda () (my/apply-modern-theme 'dark)))

;; Apply on startup
(let ((hour (string-to-number (format-time-string "%H"))))
  (if (and (>= hour 7) (< hour 18))
      (my/apply-modern-theme 'light)
    (my/apply-modern-theme 'dark)))

;; ---------------------------------------------------------------------------
;; 4. Modeline (Clean & Functional)
;; ---------------------------------------------------------------------------
(after! doom-modeline
  (setq doom-modeline-height (round (* 32 resolution-factor))
        doom-modeline-buffer-file-name-style 'relative-to-project
        doom-modeline-display-misc-in-all-mode-lines nil
        doom-modeline-enable-word-count t
        doom-modeline-hud nil ; Remove HUD for cleaner look
        doom-modeline-time-icon nil
        doom-modeline-window-width-limit 85 ; Fixed limit to prevent time truncation
        inhibit-compacting-font-caches t))

(setq display-time-format "%H:%M " ; Padded to avoid edge truncation
      display-time-default-load-average nil)
(display-time-mode t)
(display-battery-mode t)

;; ---------------------------------------------------------------------------
;; 5. Faces (Code & Org Mode)
;; ---------------------------------------------------------------------------
;; Italicize comments and keywords for a modern coding aesthetic
(custom-set-faces!
  '(font-lock-comment-face :slant italic :weight light)
  '(font-lock-keyword-face :slant italic :weight bold))

;; Org-mode styling: clean and hierarchical
(custom-set-faces!
  '(org-document-title :height 1.5 :weight bold :slant normal)
  '(org-level-1 :height 1.3 :weight bold)
  '(org-level-2 :height 1.2 :weight semi-bold)
  '(org-level-3 :height 1.1 :weight medium)
  '(org-level-4 :height 1.05 :weight normal)
  '(org-level-5 :height 1.0 :weight normal)
  '(org-drawer :height 0.9 :slant italic :weight light)
  '(org-meta-line :height 0.9 :slant italic :weight light)
  '(org-table :height 0.95)
  '(org-block :height 0.95)
  '(org-code  :height 0.95))

;; UI popups
(custom-set-faces! '((corfu-popupinfo) :height 0.85))

;; ---------------------------------------------------------------------------
;; 6. Zen Mode / Focus
;; ---------------------------------------------------------------------------
(setq +zen-text-scale 1.1
      writeroom-width 80
      writeroom-extra-line-spacing 0.2)

;; ---------------------------------------------------------------------------
;; 7. Mixed Pitch & Typo enhancements
;; ---------------------------------------------------------------------------
(defvar mixed-pitch-modes '(org-mode LaTeX-mode markdown-mode gfm-mode Info-mode)
  "Modes that `mixed-pitch-mode' should be enabled in.")

(defun init-mixed-pitch-h ()
  (when (memq major-mode mixed-pitch-modes)
    (mixed-pitch-mode 1))
  (dolist (hook mixed-pitch-modes)
    (add-hook (intern (concat (symbol-name hook) "-hook")) #'mixed-pitch-mode)))

(add-hook 'doom-init-ui-hook #'init-mixed-pitch-h)

(after! mixed-pitch
  (setq mixed-pitch-set-height t)
  (set-face-attribute 'variable-pitch-serif nil :font variable-pitch-serif-font))

;; ---------------------------------------------------------------------------
;; 8. Marginalia (Colorful minibuffer annotations)
;; ---------------------------------------------------------------------------
(after! marginalia
  (setq marginalia-censor-variables nil)

  (defadvice! +marginalia--annotate-local-file-colorful (cand)
    "A more colourful version of `marginalia--annotate-local-file'."
    :override #'marginalia--annotate-local-file
    (marginalia--in-minibuffer
      (when-let* ((attrs (ignore-errors
                           (file-attributes (substitute-in-file-name
                                             (marginalia--full-candidate cand))
                                            'integer))))
        (marginalia--fields
         ((marginalia--file-modes attrs))
         ((+marginalia-file-size-colorful (file-attribute-size attrs)) :width 7)
         ((+marginalia--time-colorful (file-attribute-modification-time attrs)) :width 12)
         ((marginalia--file-owner attrs) :face 'marginalia-file-owner)))))

  (defun +marginalia--time-colorful (time)
    (let* ((seconds (float-time (time-subtract (current-time) time)))
           (fg-date (face-attribute 'marginalia-date :foreground nil t))
           (fg-doc  (face-attribute 'marginalia-documentation :foreground nil t))
           (color (doom-blend
                   (if (stringp fg-date) fg-date "white")
                   (if (stringp fg-doc) fg-doc "gray")
                   (max 0.0 (min 1.0 (/ 1.0 (log (+ 3 (/ (+ 1 seconds) 345600.0)))))))))
      (propertize (marginalia--time time) 'face (list :foreground color))))

  (defun +marginalia-file-size-colorful (size)
    (let* ((size-index (/ (log (+ 1.0 size)) 16.118))
           (color (if (< size 10000000)
                      (doom-blend "orange" "green" (max 0.0 (min 1.0 size-index)))
                    (let ((large-index (/ (- (log (+ 1.0 size)) 16.118) 4.605)))
                      (doom-blend "red" "orange" (max 0.0 (min 1.0 large-index)))))))
      (propertize (file-size-human-readable size) 'face (list :foreground color)))))

;; ---------------------------------------------------------------------------
;; 9. Org Prettification Hook
;; ---------------------------------------------------------------------------
(defun ash/modern-org-pretty ()
  "Modern enhancements for Org."
  (require 'typopunct)
  (typopunct-change-language 'spanish)
  (typopunct-mode 1)
  (display-line-numbers-mode -1)
  (prettify-symbols-mode t)
  (+org-pretty-mode 1)
  (electric-indent-local-mode -1)
  (doom-themes-org-config)
  (add-to-list 'typopunct-language-alist
               `(spanish ,(decode-char 'ucs #xAB)
                 ,(decode-char 'ucs #xBB)
                 ,(decode-char 'ucs #x201C)
                 ,(decode-char 'ucs #x201D)))
  (setq-default typopunct-buffer-language 'spanish))

(add-hook 'org-mode-hook #'ash/modern-org-pretty)

;; ---------------------------------------------------------------------------
;; 10. Orderless (Accent matching)
;; ---------------------------------------------------------------------------
(after! orderless
  (defvar my-orderless-accent-replacements
    '(("a" . "[aàáâãäå]")
      ("e" . "[eèéêë]")
      ("i" . "[iìíîï]")
      ("o" . "[oòóôõöœ]")
      ("u" . "[uùúûü]")
      ("c" . "[cç]")
      ("n" . "[nñ]")))

  (defun my-orderless-accent-regexp (component)
    "Match COMPONENT as a regexp, but ignoring accents."
    (let ((res (seq-reduce
                (lambda (prev val)
                  (replace-regexp-in-string (car val) (cdr val) prev))
                my-orderless-accent-replacements
                component)))
      (orderless-regexp res)))

  (setq completion-styles '(orderless basic)
        completion-category-overrides '((file (styles basic partial-completion))))
  (add-to-list 'orderless-matching-styles 'my-orderless-accent-regexp))

(provide 'setup-theme-modern)
;;; setup-theme-modern.el ends here