;;; $DOOMDIR/lisp/setup-theme-lambda.el --- Sets shapes and colors  -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:
;;;

(use-package! lambda-themes
  :custom
  (lambda-themes-set-italic-comments t)
  (lambda-themes-set-italic-keywords t)
  (lambda-themes-set-variable-pitch t))

(use-package! alabaster-themes)

(defun my/apply-theme (appearance)
  "Load theme, taking current system APPEARANCE into consideration."
  (mapc #'disable-theme custom-enabled-themes)
  (pcase appearance
    ('light (load-theme 'alabaster-themes-light :no-confirm) t)
    ('dark (load-theme 'lambda-dark :no-confirm) t)))

;;Light for the day
(run-at-time "07:15" (* 60 60 24)
             (lambda ()
               (my/apply-theme 'light)))

;; Dark for the night
(run-at-time "18:00" (* 60 60 24)
             (lambda ()
               (my/apply-theme 'dark)))

;;;(my/apply-theme 'dark)

(set-default 'cursor-type  '(bar . 2))
(blink-cursor-mode 1)

;; Line spacing, can be 0 for code and 1 or 2 for text
(setq-default line-spacing 0)

;; Underline line at descent position, not baseline position
(setq x-underline-at-descent-line t)

(setq ;; user-font "iMWritingMono Nerd Font Mono"
 ;;user-font "Source Code Pro"
 ;; variable-font "Iosevka Aile"
 user-font "SF Mono"
 variable-font "SF Pro Text"
 symbols-font "Symbola")

(setq user-font-weight
      (cond
       ((string= user-font "Source Code Pro") 'regular)
       (t 'normal)))

;; calculate the font size based on display-pixel-height
(setq resolution-factor (/ (display-pixel-height) 1080.0))
(setq doom-font (font-spec :family user-font :weight user-font-weight :size (round (* 18 resolution-factor)))
      doom-big-font (font-spec :family user-font :weight user-font-weight :size (round (* 28 resolution-factor)))
      doom-variable-pitch-font (font-spec :family variable-font :weight user-font-weight :size (round (* 20 resolution-factor)))
      doom-symbol-font (font-spec :family symbols-font  :size (round (* 20 resolution-factor)))
      doom-modeline-height (round (* 30 resolution-factor)))
(setq doom-font-increment 1)

(setq default-frame-alist
      (append (list
               ;; '(min-height . 1)
               ;; '(height     . 35)
               ;; '(min-width  . 1)
               ;; '(width      . 81)
               '(vertical-scroll-bars . nil)
               '(internal-border-width . 4)
               '(left-fringe    . 20)
               '(right-fringe   . 20)
               '(tool-bar-lines . 0)
               '(menu-bar-lines . 0))
              default-frame-alist))

(setq window-divider-default-right-width 3)
(setq window-divider-default-places 'right-only)
(window-divider-mode 1)
;; (setq widget-image-enable t)

(after! doom-modeline
  (setq doom-modeline-buffer-file-name-style 'relative-to-project ;; 'truncate-with-project
        doom-modeline-display-misc-in-all-mode-lines nil
        doom-modeline-enable-word-count t
        doom-modeline-hud t
        doom-modeline-time-icon nil
        doom-modeline-window-width-limit (- fill-column 30)
        inhibit-compacting-font-caches t))

(setq display-time-format "%H:%M"
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
  '(org-code  :height 0.9 :family "Courier New"))

(custom-set-faces!
  '(outline-1 :height 1.4  :weight medium)
  '(outline-2 :height 1.2  :weight medium)
  '(outline-3 :height 1.1  :weight medium)
  '(outline-4 :height 1.0  :weight medium)
  '(org-document-title :height 1.6 :weight light :underline nil))

;; (font-lock-add-keywords 'org-mode
;;                         '(("^\\(?:[  ]*\\)\\(?:[-+]\\|[ ]+\\*\\|\\(?:[0-9]+\\|[A-Za-z]\\)[.)]\\)?[ ]+"
;;                            . 'fixed-pitch)))
;; (font-lock-add-keywords 'org-mode '(("(\\?)" . 'error)))
;; )


(custom-set-faces! '((corfu-popupinfo) :height 0.8))

(add-hook 'text-mode-hook (lambda () (hl-line-mode -1)))

(defface variable-pitch-serif
  '((t (:family "serif")))
  "A variable-pitch face with serifs."
  :group 'basic-faces)

(defcustom variable-pitch-serif-font (font-spec :family "Alegreya" :size 26)
  "The font face used for `variable-pitch-serif'."
  :group 'basic-faces
  :type '(restricted-sexp :tag "font-spec" :match-alternatives (fontp))
  :set (lambda (symbol value)
         (set-face-attribute 'variable-pitch-serif nil :font value)
         (set-default-toplevel-value symbol value)))

(defvar mixed-pitch-modes '(org-mode LaTeX-mode markdown-mode gfm-mode Info-mode)
  "Modes that `mixed-pitch-mode' should be enabled in, but only after UI initialisation.")

(defun init-mixed-pitch-h ()
  "Hook `mixed-pitch-mode' into each mode in `mixed-pitch-modes'.
Also immediately enables `mixed-pitch-modes' if currently in one of the modes."
  (when (memq major-mode mixed-pitch-modes)
    (mixed-pitch-mode 1))
  (dolist (hook mixed-pitch-modes)
    (add-hook (intern (concat (symbol-name hook) "-hook")) #'mixed-pitch-mode)))

(add-hook 'doom-init-ui-hook #'init-mixed-pitch-h)

(after! mixed-pitch
  (setq mixed-pitch-set-height t)
  (set-face-attribute 'variable-pitch-serif nil :font variable-pitch-serif-font)

  (defun mixed-pitch-serif-mode (&optional arg)
    "Change the default face of the current buffer to a serifed variable pitch, while keeping some faces fixed pitch."
    (interactive)
    (let ((mixed-pitch-face 'variable-pitch-serif))
      (mixed-pitch-mode (or arg 'toggle)))))

(autoload #'mixed-pitch-serif-mode "mixed-pitch"
  "Change the default face of the current buffer to a serifed variable pitch, while keeping some faces fixed pitch." t)

(set-char-table-range composition-function-table ?f '(["\\(?:ff?[fijlt]\\)" 0 font-shape-gstring]))
(set-char-table-range composition-function-table ?T '(["\\(?:Th\\)" 0 font-shape-gstring]))

;; (after! marginalia
;;   (setq marginalia-censor-variables nil)

;;   (defadvice! +marginalia--anotate-local-file-colorful (cand)
;;     "Just a more colourful version of `marginalia--anotate-local-file'."
;;     :override #'marginalia--annotate-local-file
;;     (when-let (attrs (file-attributes (substitute-in-file-name
;;                                        (marginalia--full-candidate cand))
;;                                       'integer))
;;       (marginalia--fields
;;        ((marginalia--file-owner attrs)
;;         :width 12 :face 'marginalia-file-owner)
;;        ((marginalia--file-modes attrs))
;;        ((+marginalia-file-size-colorful (file-attribute-size attrs))
;;         :width 7)
;;        ((+marginalia--time-colorful (file-attribute-modification-time attrs))
;;         :width 12))))

;;   (defun +marginalia--time-colorful (time)
;;     (let* ((seconds (float-time (time-subtract (current-time) time)))
;;            (color (doom-blend
;;                    (face-attribute 'marginalia-date :foreground nil t)
;;                    (face-attribute 'marginalia-documentation :foreground nil t)
;;                    (/ 1.0 (log (+ 3 (/ (+ 1 seconds) 345600.0)))))))
;;       ;; 1 - log(3 + 1/(days + 1)) % grey
;;       (propertize (marginalia--time time) 'face (list :foreground color))))

;;   (defun +marginalia-file-size-colorful (size)
;;     (let* ((size-index (/ (log (+ 1 size)) 7.0))
;;            (color (if (< size-index 10000000) ; 10m
;;                       (doom-blend 'orange 'green size-index)
;;                     (doom-blend 'red 'orange (- size-index 1)))))
;;       (propertize (file-size-human-readable size) 'face (list :foreground color)))))


(setq +zen-text-scale 1.0
      writeroom-width 65
      ;; writeroom-mode-line t
      writeroom-extra-line-spacing 0.1)


(defun ash/pretty ()
  "Some enhancements for Org."
  (require 'typopunct)
  (typopunct-change-language 'spanish)
  (typopunct-mode 1)
  (display-line-numbers-mode -1)
  (prettify-symbols-mode t)
  (+org-pretty-mode 1)
  (electric-indent-local-mode -1)
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

(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; (after! doom-modeline
;;   (doom-modeline-def-segment buffer-name
;;     "Display the current buffer's name, without any other information."
;;     (concat
;;      (doom-modeline-spc)
;;      (doom-modeline--buffer-name)))

;;   (doom-modeline-def-segment pdf-icon
;;     "PDF icon from nerd-icons."
;;     (concat
;;      (doom-modeline-icon sucicon "nf-seti-pdf" nil nil
;;                          (doom-modeline-spc)
;;                          :face (if (doom-modeline--active)
;;                                    'nerd-icons-red
;;                                  'mode-line-inactive)
;;                          :v-adjust 0.02)))

;;   (defun doom-modeline-update-pdf-pages ()
;;     "Update PDF pages."
;;     (setq doom-modeline--pdf-pages
;;           (let ((current-page-str (number-to-string (pdf-view-current-page)))
;;                 (total-page-str (number-to-string (pdf-cache-number-of-pages))))
;;             (concat
;;              (propertize
;;               (concat (make-string (- (length total-page-str) (length current-page-str)) ? )
;;                       " P" current-page-str)
;;               'face 'mode-line)
;;              (propertize (concat "/" total-page-str) 'face 'doom-modeline-buffer-minor-mode)))))

;;   (doom-modeline-def-segment pdf-pages
;;     "Display PDF pages."
;;     (if (doom-modeline--active) doom-modeline--pdf-pages
;;       (propertize doom-modeline--pdf-pages 'face 'mode-line-inactive)))

;;   (doom-modeline-def-modeline 'pdf
;;     '(bar window-number pdf-pages pdf-icon buffer-name)
;;     '(misc-info matches major-mode process vcs))
;;   )

;; (after! orderless
;;   (defvar my-orderless-accent-replacements
;;     '(("a" . "[aàáâãäå]")
;;       ("e" . "[eèéêë]")
;;       ("i" . "[iìíîï]")
;;       ("o" . "[oòóôõöœ]")
;;       ("u" . "[uùúûü]")
;;       ("c" . "[cç]")
;;       ("n" . "[nñ]")) ; in case anyone needs ñ for Spanish

;;     (defun my-orderless-accent-dispatch (pattern &rest _)
;;       (seq-reduce
;;        (lambda (prev val)
;;          (replace-regexp-in-string (car val) (cdr val) prev))
;;        my-orderless-accent-replacements
;;        pattern)))

;;   (setq completion-styles '(orderless basic)
;;         completion-category-overrides '((file (styles basic partial-completion)))
;;         orderless-style-dispatchers '(my-orderless-accent-dispatch orderless-affix-dispatch)))


(provide 'setup-theme-lambda)
;;; setup-theme-lambda.el ends here
