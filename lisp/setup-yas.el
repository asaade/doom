;;; lisp/setup-yas.el -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:
;;;

(setq +snippets-dir (expand-file-name "snippets/" doom-user-dir))

;;
;;; Packages

(use-package! yasnippet
  :defer-incrementally eldoc easymenu help-mode
  :commands (yas-minor-mode-on
             yas-expand
             yas-expand-snippet
             yas-lookup-snippet
             yas-insert-snippet
             yas-new-snippet
             yas-visit-snippet-file
             yas-activate-extra-mode
             yas-deactivate-extra-mode
             yas-maybe-expand-abbrev-key-filter)
  :init
  ;; Reduce default verbosity. 3 is too chatty about initializing yasnippet. 2
  ;; is just right (only shows errors).
  (defvar yas-verbosity 2)

  ;; Remove default ~/.emacs.d/snippets
  (defvar yas-snippet-dirs nil)

  ;; Lazy load yasnippet until it is needed
  (add-transient-hook! #'company-yasnippet (require 'yasnippet))

  :config
  ;;(add-to-list 'doom-debug-variables '(yas-verbosity . 3))

  ;; Allow private snippets in DOOMDIR/snippets
  (add-to-list 'yas-snippet-dirs '+snippets-dir)

  ;; default snippets library, if available
  (add-to-list 'load-path +snippets-dir)
  (require 'doom-snippets nil t)

  ;; HACK In case `+snippets-dir' and `doom-snippets-dir' are the same, or
  ;;      duplicates exist in `yas-snippet-dirs'.
  (defadvice! +snippets--remove-duplicate-dirs-a (dirs)
    :filter-return #'yas-snippet-dirs
    (cl-delete-duplicates dirs :test #'string= :key #'expand-file-name :from-end t))

  ;; Remove GUI dropdown prompt (prefer ivy/helm)
  ; (delq! 'yas-dropdown-prompt yas-prompt-functions)
  ;; Prioritize private snippets in `+snippets-dir' over built-in ones if there
  ;; are multiple choices.
  (add-to-list 'yas-prompt-functions #'+snippets-prompt-private)

  ;; Register `def-project-mode!' modes with yasnippet. This enables project
  ;; specific snippet libraries (e.g. for Laravel, React or Jekyll projects).
  ;; (add-hook 'doom-project-hook #'+snippets-enable-project-modes-h)

  ;; Exit snippets on ESC from normal mode
  (add-hook 'doom-escape-hook #'yas-abort-snippet)

  (after! smartparens
    ;; tell smartparens overlays not to interfere with yasnippet keybinds
    (advice-add #'yas-expand :before #'sp-remove-active-pair-overlay))

  ;; (Evil only) fix off-by-one issue with line-wise visual selections in
  ;; `yas-insert-snippet', and switches to insert mode afterwards.
  (advice-add #'yas-insert-snippet :around #'+snippets-expand-on-region-a)

  ;; Show keybind hints in snippet header-line
  (add-hook 'snippet-mode-hook #'+snippets-show-hints-in-header-line-h)
  ;; Enable `read-only-mode' for built-in snippets (in `doom-local-dir')
  (add-hook 'snippet-mode-hook #'+snippets-read-only-maybe-h)

  (map! (:map yas-keymap
         "C-e"         #'+snippets/goto-end-of-field
         "C-a"         #'+snippets/goto-start-of-field
         [M-right]     #'+snippets/goto-end-of-field
         [M-left]      #'+snippets/goto-start-of-field
         [M-backspace] #'+snippets/delete-to-start-of-field
         [backspace]   #'+snippets/delete-backward-char
         [delete]      #'+snippets/delete-forward-char-or-field
         ;; Replace commands with superior alternatives
         :map yas-minor-mode-map
         [remap yas-new-snippet]        #'+snippets/new
         [remap yas-visit-snippet-file] #'+snippets/edit)
        (:map snippet-mode-map
         "C-c C-k" #'+snippet--abort))

  ;; REVIEW Fix #2639: For some reason `yas--all-templates' returns duplicates
  ;;        of some templates. Until I figure out the real cause this fixes it.
  (defadvice! +snippets--remove-duplicates-a (templates)
    :filter-return #'yas--all-templates
    (cl-delete-duplicates templates :test #'equal))

  ;; HACK Smartparens will interfere with snippets expanded by `hippie-expand`,
  ;;      so temporarily disable smartparens during snippet expansion.
  (after! hippie-exp
    (defvar +snippets--smartparens-enabled-p t)
    (defvar +snippets--expanding-p nil)

    ;; Is called for all snippet expansions,
    (add-hook! 'yas-before-expand-snippet-hook
      (defun +snippets--disable-smartparens-before-expand-h ()
        ;; Remember the initial smartparens state only once, when expanding a
        ;; top-level snippet.
        (unless +snippets--expanding-p
          (setq +snippets--expanding-p t
                +snippets--smartparens-enabled-p smartparens-mode))
        (when smartparens-mode
          (smartparens-mode -1))))

    ;; Is called only for the top level snippet, but not for the nested ones.
    ;; Hence `+snippets--expanding-p'.
    (add-hook! 'yas-after-exit-snippet-hook
      (defun +snippets--restore-smartparens-after-expand-h ()
        (setq +snippets--expanding-p nil)
        (when +snippets--smartparens-enabled-p
          (smartparens-mode 1)))))

  ;; If in a daemon session, front-load this expensive work:
  (yas-global-mode +1))


(use-package! auto-yasnippet
  :defer t
  :config
  (setq aya-persist-snippets-dir +snippets-dir)
  (defadvice! +snippets--inhibit-yas-global-mode-a (fn &rest args)
    "auto-yasnippet enables `yas-global-mode'. This is obnoxious for folks like
us who use yas-minor-mode and enable yasnippet more selectively. This advice
swaps `yas-global-mode' with `yas-minor-mode'."
    :around '(aya-expand aya-open-line)
    (letf! ((#'yas-global-mode #'yas-minor-mode)
            (yas-global-mode yas-minor-mode))
      (apply fn args))))


(defun +yas/org-src-header-p ()
  "Determine whether `point' is within a src-block header or header-args."
  (pcase (org-element-type (org-element-context))
    ('src-block (< (point) ; before code part of the src-block
                   (save-excursion (goto-char (org-element-property :begin (org-element-context)))
                                   (forward-line 1)
                                   (point))))
    ('inline-src-block (< (point) ; before code part of the inline-src-block
                          (save-excursion (goto-char (org-element-property :begin (org-element-context)))
                                          (search-forward "]{")
                                          (point))))
    ('keyword (string-match-p "^header-args" (org-element-property :value (org-element-context))))))




(defun +yas/org-prompt-header-arg (arg question values)
  "Prompt the user to set ARG header property to one of VALUES with QUESTION.
The default value is identified and indicated. If either default is selected,
or no selection is made: nil is returned."
  (let* ((src-block-p (not (looking-back "^#\\+property:[ \t]+header-args:.*" (line-beginning-position))))
         (default
          (or
           (cdr (assoc arg
                       (if src-block-p
                           (nth 2 (org-babel-get-src-block-info t))
                         (org-babel-merge-params
                          org-babel-default-header-args
                          (let ((lang-headers
                                 (intern (concat "org-babel-default-header-args:"
                                                 (+yas/org-src-lang)))))
                            (when (boundp lang-headers) (eval lang-headers t)))))))
           ""))
         default-value)
    (setq values (mapcar
                  (lambda (value)
                    (if (string-match-p (regexp-quote value) default)
                        (setq default-value
                              (concat value " "
                                      (propertize "(default)" 'face 'font-lock-doc-face)))
                      value))
                  values))
    (let ((selection (consult--read values :prompt question :default default-value)))
      (unless (or (string-match-p "(default)$" selection)
                  (string= "" selection))
        selection))))

(defun +yas/org-src-lang ()
  "Try to find the current language of the src/header at `point'.
Return nil otherwise."
  (let ((context (org-element-context)))
    (pcase (org-element-type context)
      ('src-block (org-element-property :language context))
      ('inline-src-block (org-element-property :language context))
      ('keyword (when (string-match "^header-args:\\([^ ]+\\)" (org-element-property :value context))
                  (match-string 1 (org-element-property :value context)))))))

(defun +yas/org-last-src-lang ()
  "Return the language of the last src-block, if it exists."
  (save-excursion
    (beginning-of-line)
    (when (re-search-backward "^[ \t]*#\\+begin_src" nil t)
      (org-element-property :language (org-element-context)))))

(defun +yas/org-most-common-no-property-lang ()
  "Find the lang with the most source blocks that has no global header-args, else nil."
  (let (src-langs header-langs)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*#\\+begin_src" nil t)
        (push (+yas/org-src-lang) src-langs))
      (goto-char (point-min))
      (while (re-search-forward "^[ \t]*#\\+property: +header-args" nil t)
        (push (+yas/org-src-lang) header-langs)))

    (setq src-langs
          (mapcar #'car
                  ;; sort alist by frequency (desc.)
                  (sort
                   ;; generate alist with form (value . frequency)
                   (cl-loop for (n . m) in (seq-group-by #'identity src-langs)
                            collect (cons n (length m)))
                   (lambda (a b) (> (cdr a) (cdr b))))))

    (car (cl-set-difference src-langs header-langs :test #'string=))))


(provide 'setup-yas)
;;; setup-yas.el ends here
