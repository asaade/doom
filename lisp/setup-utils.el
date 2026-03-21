;;; lisp/setup-utils.el --- varias utilerías -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:
;;;

(global-set-key [mouse-3] 'mouse-popup-menubar-stuff)          ; Gives right-click a context menu
(global-set-key (kbd "M-DEL") 'sanemacs/backward-kill-word)    ; Kill word without copying it to your clipboard
(global-set-key (kbd "C-DEL") 'sanemacs/backward-kill-word)    ; Kill word without copying it to your clipboard


(after! ispell
  (let ((langs '("spanish" "american" "francais")))
    (setq lang-ring (make-ring (length langs)))
    (dolist (elem langs) (ring-insert lang-ring elem)))
  (defun cycle-ispell-languages ()
    (interactive)
    (let ((lang (ring-ref lang-ring -1)))
      (ring-insert lang-ring lang)
      (ispell-change-dictionary lang)))
  (setq ispell-dictionary "spanish")
  (setq ispell-local-dictionary "spanish")
  (setq ispell-local-dictionary-alist
        '(("spanish" "[[:alpha:]]" "[^[:alpha:]]" "[']" nil nil nil utf-8))
        ispell-alternate-dictionary "/usr/share/dict/words")

  (global-set-key [f6] 'cycle-ispell-languages))

(setq langtool-default-language "es"
      ;; langtool-language-tool-jar "/usr/share/java/languagetool/languagetool.jar"
      )

(use-package! visual-regexp-steroids
  :defer 3
  :config
  (require 'pcre2el)
  (setq vr/engine 'pcre2el)
  (map! "C-c s r" #'vr/replace)
  (map! "C-c s q" #'vr/query-replace))

;; (use-package! vlf-setup
;;   :defer-incrementally vlf-tune vlf-base vlf-write vlf-search vlf-occur vlf-follow vlf-ediff vlf
;;   ;; :config
;;   ;; (vlf-application 'dont-ask)
;;   )

(after! ediff
  (setq ediff-keep=variants nil
        ediff-make-buffers-readonly-at-startup nil
        ediff-merge-with-ancestor-job t
        ediff-show-clashes-only t
        ediff-split-window-function 'split-window-horizontally
        ediff-window-setup-function 'ediff-setup-windows-plain))

;; ;; https://pages.sachachua.com/.emacs.d/Sacha.html
(defun screenshot-svg ()
  "Save a screenshot of the current frame as an SVG image.
Saves to a temp file and puts the filename in the kill ring."
  (interactive)
  (let* ((filename (format-time-string "~/Pictures/%Y%m%dT%H%M%S-EmacsScreenshot.svg"))
         (data (x-export-frames nil 'svg)))
    (with-temp-file filename
      (insert data))
    (kill-new filename)
    (message filename)))
(global-set-key (kbd "C-c u") #'screenshot-svg)

(defun insert-current-date () (interactive)
       (insert (format-time-string "%Y-%m-%d")))


(defun insdate-insert-current-date (&optional omit-day-of-week-p)
  "Insert today's date using the current locale.
  With a prefix argument, the date is inserted without the day of
  the week."
  (interactive "P*")
  (insert (calendar-date-string (calendar-current-date) nil
                                omit-day-of-week-p)))

(defun insdate-insert-any-date (date)
  "Insert DATE using the current locale."
  (interactive (list (calendar-read-date)))
  (insert (calendar-date-string date)))


(defun insdate-insert-date-from (&optional days)
  "Insert date that is DAYS from current."
  (interactive (list (read-number (format "days: ") 0)))
  (insert
   (calendar-date-string
    (calendar-gregorian-from-absolute
     (+ (calendar-absolute-from-gregorian (calendar-current-date))
        days))
    t)))


(defun help/insert-em-dash ()
  "Inserts an EM-DASH (not a HYPEN, not an N-DASH)"
  (interactive)
  (insert "—"))

(defun help/insert-en-dash ()
  "Inserts an EN-DASH (not a HYPEN, not an EM-DASH)"
  (interactive)
  (insert "–"))

(defun my-fill-or-unfill-paragraph (&optional unfill region)
  "Fill paragraph (or REGION).
   With the prefix argument UNFILL, unfill it instead."
  (interactive (progn
                 (barf-if-buffer-read-only)
                 (list (if current-prefix-arg 'unfill) t)))
  (let ((fill-column (if unfill (point-max) fill-column)))
    (fill-paragraph nil region)))
(bind-key "M-q" 'my-fill-or-unfill-paragraph)

(defun ash/copy-file-name-to-clipboard ()
  "Copy the current buffer file name to the clipboard."
  (interactive)
  (let ((filename (if (equal major-mode 'dired-mode) default-directory (buffer-file-name))))
    (when filename
      (kill-new filename)
      (message "Copied buffer file name '%s' to the clipboard." filename))))

(defun ash/cleanup-buffer-safe ()
  "Perform a bunch of safe operations on the whitespace content of a buffer.
Does not indent buffer, because it is used for a before-save-hook, and that
might be bad."
  (interactive)
  (untabify (point-min) (point-max))
  (delete-trailing-whitespace)
  (set-buffer-file-coding-system 'utf-8))


(defun ash/cleanup-buffer ()
  "Perform a bunch of operations on the whitespace content of a buffer.
Including indent-buffer, which should not be called automatically on save."
  (interactive)
  (ash/cleanup-buffer-safe)
  (indent-region (point-min) (point-max)))

(add-hook 'before-save-hook 'ash/cleanup-buffer-safe)

(defun ash/kill-other-buffers ()
  "Kill all other buffers."
  (interactive)
  (mapc 'kill-buffer
        (delq (current-buffer)
              (seq-filter 'buffer-file-name (buffer-list)))))

(defun ash/kill-this-buffer-volatile ()
  "Kill current buffer, even if it has been modified."
  (interactive)
  (set-buffer-modified-p nil)
  (kill-this-buffer))

(defun prot/keyboard-quit-dwim ()
  "Do-What-I-Mean behaviour for a general `keyboard-quit'.

The generic `keyboard-quit' does not do the expected thing when
the minibuffer is open.  Whereas we want it to close the
minibuffer, even without explicitly focusing it.

The DWIM behaviour of this command is as follows:

- When the region is active, disable it.
- When a minibuffer is open, but not focused, close the minibuffer.
- When the Completions buffer is selected, close it.
- In every other case use the thin `keyboard-quit'."
  (interactive)
  (cond
   ((region-active-p)
    (keyboard-quit))
   ((derived-mode-p 'completion-list-mode)
    (delete-completion-window))
   ((> (minibuffer-depth) 0)
    (abort-recursive-edit))
   (t
    (keyboard-quit))))

(defun goto-last-modification ()
  (interactive)
  (undo-fu-only-undo)
  (undo-fu-only-redo))

;; (use-package! substitute
;;   :config
;;   (add-hook 'substitute-post-replace-functions #'substitute-report-operation)
;;   (let ((map global-map))
;;     (define-key map (kbd "M-# s") #'substitute-target-below-point)
;;     (define-key map (kbd "M-# r") #'substitute-target-above-point)
;;     (define-key map (kbd "M-# d") #'substitute-target-in-defun)
;;     (define-key map (kbd "M-# b") #'substitute-target-in-buffer)))


(defun ash/save-shebanged-file-as-executable ()
  (and (save-excursion
         (save-restriction
           (widen)
           (goto-char (point-min))
           (save-match-data
             (looking-at "^#!"))))
       (not (file-executable-p buffer-file-name))
       (shell-command (concat "chmod +x " (shell-quote-argument buffer-file-name)))
       (message
        (concat "Saved as script: " buffer-file-name))))


(map! "M-n M-n" (cmd! (insert "\u200B")))


;; ;;;###autoload
;; (defadvice! my-super-backward-delete-a (&rest _)
;;   "Special function to super-delete things.

;; If the line content before cursor contains only blank characters, this function
;; will delete all the blank characters, and then, join with the previous line. I
;; there is any non-blank character before cursor, this function will delete the
;; entire line, but keep the correct indentation on it."
;;   :before '+default--delete-backward-char-a
;;   (let* ((line-pos (- (point) (point-at-bol)))
;;          (prev-indent (save-excursion
;;                         (forward-line -1)
;;                         (current-indentation)))
;;          (prev-line-bol (point-at-bol 0))
;;          (next-line-eol (point-at-eol 2))
;;          (smart-bs-p (or (save-excursion
;;                            (and (re-search-backward "{[ \t]*\n[ \t]*" prev-line-bol t)
;;                                 (re-search-forward "[ \t]*\n[ \t]*}" next-line-eol t)))
;;                          (save-excursion
;;                            (and (re-search-backward "\\[[ \t]*\n[ \t]*" prev-line-bol t)
;;                                 (re-search-forward "[ \t]*\n[ \t]*\\]" next-line-eol t)))
;;                          (save-excursion
;;                            (and (re-search-backward "([ \t]*\n[ \t]*" prev-line-bol t)
;;                                 (re-search-forward "[ \t]*\n[ \t]*)" next-line-eol t))))))
;;     (when (and smart-bs-p
;;                (<= line-pos (+ prev-indent standard-indent)))
;;       (delete-char (- line-pos)))))


(defun jethro/open-with (arg)
  "Open visited file in default external program.
When in dired mode, open file under the cursor.
With a prefix ARG always prompt for command to use."
  (interactive "P")
  (let* ((current-file-name
          (if (eq major-mode 'dired-mode)
              (dired-get-file-for-visit)
            buffer-file-name))
         (open (pcase system-type
                 (`darwin "open")
                 ((or `gnu `gnu/linux `gnu/kfreebsd) "xdg-open")))
         (program (if (or arg (not open))
                      (read-shell-command "Open current file with: ")
                    open)))
    (call-process program nil 0 nil current-file-name)))

(map! "C-c o o" 'jethro/open-with)


(defun ash/save-ignore-errors ()
  "Save all buffers, ignoring errors."
  (ignore-errors
    (save-some-buffers)))

(add-hook 'kill-emacs-hook 'ash/save-ignore-errors)

;; Automatically create parent directories when saving files
(defun ash/my-create-non-existent-directory ()
  "Create parent directories for the current buffer file if they do not exist."
  (let ((parent-directory (file-name-directory buffer-file-name)))
    (when (and (not (file-exists-p parent-directory))
               (y-or-n-p (format "Directory `%s' does not exist! Create it?" parent-directory)))
      (make-directory parent-directory t))))

(add-to-list 'find-file-not-found-functions 'ash/my-create-non-existent-directory)

;; Reload directory locals
(defun ash/reload-dir-locals-for-current-buffer ()
  "Reload directory locals for the current buffer."
  (interactive)
  (let ((enable-local-variables :all))
    (hack-dir-local-variables-non-file-buffer)))

(defun eval-and-replace ()
  "Replace the preceding sexp with its value."
  (interactive)
  (backward-kill-sexp)
  (condition-case nil
      (prin1 (eval (read (current-kill 0)))
             (current-buffer))
    (error (message "Invalid expression")
           (insert (current-kill 0)))))


(use-package! iedit)

(after! pdf-tools
  (setq-default pdf-view-display-size 'fit-width)
  (setq pdf-annot-activate-created-annotations t
        pdf-view-resize-factor 0.8))

;; (use-package! go-translate
;;   :config
;;   (setq gt-translate-list '(("en" "es"))
;;         gt-default-translator
;;         (gt-translator
;;          :taker (gt-taker :langs '(es en) :text 'sentence)
;;          :engines (gt-google-engine)
;;          :render (gt-insert-render))))


(use-package! format-all
  :preface
  (defun ian/format-code ()
    "Auto-format whole buffer."
    (interactive)
    (if (derived-mode-p 'prolog-mode)
        (prolog-indent-buffer)
      (format-all-buffer)))
  :config
  ;;(global-set-key (kbd "M-F") #'ian/format-code)
  (add-hook 'prog-mode-hook #'format-all-ensure-formatter))


;; (use-package! gptel
;;   :config
;;   (setq gptel-api-key "your key"
;;         gptel-default-mode 'org-mode
;;         gptel-expert-commads t)
;;   (setq gptel-model 'llama3.2:latest
;;         gptel-backend (gptel-make-ollama "Ollama"
;;                                          :host "localhost:11434"
;;                                          :stream t
;;                                          :models '(deepseek-r1:7b
;;                                                    llama3.2:latest)))
;;   (defun ash/gptel-fix-src-header (beg end)
;;     (save-excursion
;;       (goto-char beg)
;;       (while (re-search-forward "^#\\+begin_src bash" end t)
;;         (replace-match "#+begin_src sh"))))

;;   (add-hook 'gptel-post-response-functions #'ash/gptel-fix-src-header)
;;   (add-to-list 'display-buffer-alist
;;                '("^*Ollama*" display-buffer-same-window))
;;   (add-hook 'gptel-post-stream-hook 'gptel-auto-scroll)
;;   (add-hook 'gptel-post-response-functions 'gptel-end-of-response))

;; (use-package! smerge-mode
;;   :hook
;;   (prog-mode . smerge-mode))

;; ;; Llama.cpp offers an OpenAI compatible API
;; (gptel-make-openai "llama-cpp"          ;Any name
;;   :stream t                             ;Stream responses
;;   :protocol "http"
;;   :host "localhost:8000"                ;Llama.cpp server location
;;   :models '(test))                    ;Any names, doesn't matter for Llama

;; (defmacro my-insert-unicode (unicode-name)
;;   `(lambda () (interactive)
;;      (insert-char (cdr (assoc-string ,unicode-name (ucs-names))))))

;; (bind-key "C-x 8 s" (my-insert-unicode "ZERO WIDTH SPACE"))

;; https://blog.kaorubb.org/en/posts/gpt-mcp-setup/
;; (use-package! gptel
;;   :config
;;   (require 'gptel-integrations)
;;   (require 'gptel-org)
;;   (setq gptel-model 'gpt-4.1
;;         gptel-default-mode 'org-mode
;;         gptel-use-curl t
;;         gptel-use-tools t
;;         gptel-confirm-tool-calls 'always
;;         gptel-include-tool-results 'auto
;;         gptel--system-message (concat gptel--system-message " Make sure to use Japanese language.")
;;         gptel-backend (gptel-make-gh-copilot "Copilot" :stream t))
;;   (gptel-make-xai "Grok" :key "your-api-key" :stream t)
;;   (gptel-make-deepseek "DeepSeek" :key "your-api-key" :stream t))



;; (use-package! gptel
;;   :commands gptel gptel-menu gptel-mode gptel-send
;;   :config
;;   (let ((groq-backend
;;          (gptel-make-openai "Groq"
;;            :host "api.groq.com"
;;            :endpoint "/openai/v1/chat/completions"
;;            :stream t
;;            :key (lambda () (or (secrets-get-secret "Login" "groq")
;;                           (secrets-get-secret "kdewallet" "groq")))
;;            :models '("llama3-70b-8192"
;;                      "llama3-8b-8192"
;;                      "llama-3.1-70b-versatile"
;;                      "llama-3.1-8b-instant"
;;                      "llama-3.2-1b-preview"
;;                      "deepseek-r1-distill-llama-70b"
;;                      "mixtral-8x7b-32768"
;;                      "gemma-7b-it"
;;                      "gemma2-9b-it")))
;;         (openai-backend
;;          (gptel-make-openai "ChatGPT"
;;            :host "api.openai.com"
;;            :stream t
;;            :key (lambda () (or (secrets-get-secret "Login" "openai")
;;                           (secrets-get-secret "kdewallet" "openai")))
;;            :models '("gpt-4o" "gpt-4o-mini" "chatgpt-4o-latest"
;;                      "o1" "o1-mini")))
;;         (anthropic-backend
;;          (gptel-make-anthropic "Claude"
;;            :stream t
;;            :key (lambda () (or (secrets-get-secret "Login" "anthropic")
;;                           (secrets-get-secret "kdewallet" "anthropic")))
;;            :models '("claude-3-5-sonnet-20240620"
;;                      "claude-3-sonnet-20240229"
;;                      "claude-3-haiku-20240307")))
;;         (ollama-backend
;;          (let (ollama-models)
;;            (when (executable-find "ollama")
;;              (with-temp-buffer
;;                (call-process "ollama" nil t nil "list")
;;                (goto-char (point-min))
;;                (forward-line 1)
;;                (while (and (not (eobp)) (looking-at "[^ \t]+"))
;;                  (push (match-string 0) ollama-models)
;;                  (forward-line 1)))
;;              (gptel-make-ollama "Ollama" :models ollama-models :stream t)))))
;;     (setq-default gptel-model "llama-3.1-70b-versatile"
;;                   gptel-backend groq-backend))
;;   (delete (assoc "ChatGPT" gptel--known-backends) gptel--known-backends)
;;   (setq gptel-default-mode #'org-mode))



;; https://sachachua.com/dotemacs/index.html#embark-audio
(defun my-embark-audio ()
  "Match audio."
  (let ((extensions "m4a\\|mp3\\|wav\\|ogg\\|opus"))
    (if-let ((link (and (derived-mode-p 'org-mode)
                        (org-element-context))))
        (when (eq (org-element-type link) 'link)
          (cond
           ((string-match extensions (org-element-property :path link))
            (cons 'audio (org-element-property :path link)))))
      (when (and (derived-mode-p 'dired-mode)
                 (string-match extensions (dired-get-filename)))
        (cons 'audio (dired-get-filename))))))

(defun my-audio-text (file &optional insert)
  "Get the text for FILE audio.
If called interactively, copy to the kill ring."
  (interactive (list (read-file-name "Audio: ")))
  (let (text)
    (cond
     ((file-exists-p (concat (file-name-sans-extension file) ".txt"))
      (with-temp-buffer
        (insert-file-contents (concat (file-name-sans-extension file) ".txt"))
        (setq text (buffer-string))))
     ;; no txt yet, is there a vtt?
     ((file-exists-p (concat (file-name-sans-extension file) ".vtt"))
      (setq text (subed-subtitle-list-text
                  (subed-parse-file (concat (file-name-sans-extension file) ".vtt")))))
     ;; no VTT, let's recognize it
     (t
      (my-deepgram-recognize-audio file)
      (when (file-exists-p (concat (file-name-sans-extension file) ".vtt"))
        (setq text (subed-subtitle-list-text
                    (subed-parse-file (concat (file-name-sans-extension file) ".vtt")))))))
    (when text
      (when (called-interactively-p 'any)
        (if insert
            (insert text "\n")
          (kill-new text)))
      text)))

(defun my-open-in-audacity (file)
  (interactive "FFile: ")
  (start-process "audacity" nil "audacity" file))

(with-eval-after-load 'embark
  (add-to-list 'embark-target-finders 'my-embark-audio)
  (defvar-keymap my-embark-audio-actions
    :doc "audio"
    "a" #'my-open-in-audacity
    "d" #'my-deepgram-recognize-audio
    "$" #'my-deepgram-cost
    "D" #'my-audio-braindump-reprocess
    "m" #'mpv-play
    "w" #'my-audio-text
    "W" #'waveform-show)
  (add-to-list 'embark-keymap-alist '(audio . my-embark-audio-actions)))


(defun my-embark-video ()
  "Match video."
  (let ((extensions "youtu\\.?be\\|\\(webm\\|mp4\\|flv\\)$"))
    (if-let ((link (and (derived-mode-p 'org-mode)
                        (org-element-context))))
        (when (eq (org-element-type link) 'link)
          (cond
           ((string-match extensions (org-element-property :path link))
            (cons 'video (org-element-property :path link)))))
      (when (and (derived-mode-p 'dired-mode)
                 (string-match extensions (dired-get-filename)))
        (cons 'video (dired-get-filename))))))

(with-eval-after-load 'embark
  (add-to-list 'embark-target-finders 'my-embark-video)
  (defvar-keymap my-embark-video-actions
    :doc "video"
    "d" #'my-deepgram-recognize-audio
    "$" #'my-deepgram-cost
    "m" #'mpv-play
    "c" #'my-caption-show
    "w" #'my-audio-text
    "W" #'waveform-show)
  (add-to-list 'embark-keymap-alist '(video . my-embark-video-actions)))


(defun my-insert-file-as-org-include (file)
  (interactive "fFile: ")
  (set-text-properties 0 (length file) nil file)
  (let ((mode (assoc-default file auto-mode-alist 'string-match)))
    (insert
     (org-link-make-string (concat "file:" file) (concat "Download " (file-name-nondirectory file))) "\n"
     "#+begin_my_details " (file-name-nondirectory file) "\n"
     (format "#+INCLUDE: %s" (prin1-to-string file))
     (if mode
         (concat " src " (replace-regexp-in-string "-mode$" "" (symbol-name mode)))
       "")
     "\n"
     "#+end_my_details\n")))

(defun my-transform-org-link-to-include ()
  (interactive)
  (let ((link (org-element-lineage (org-element-context) '(link) t))
        (mode (assoc-default (org-element-property :path link) auto-mode-alist 'string-match)))
    (when link
      (delete-region (org-element-property :begin link)
                     (org-element-property :end link))
      (my-insert-file-as-org-include (org-element-property :path link)))))


(with-eval-after-load 'embark
  (define-key embark-file-map "O" #'my-insert-file-as-org-include))



(setq code-cells-convert-ipynb-style '(
                                       ("pandoc" "--to" "ipynb" "--from" "org")
                                       ("pandoc" "--to" "org" "--from" "ipynb")
                                       org-mode))

(defun my-embark-org-element ()
  "Target an Org Mode element at point."
  (save-window-excursion
    (save-excursion
      (save-restriction
        (when (derived-mode-p 'org-agenda-mode)
          (org-goto-marker-or-bmk (org-get-at-bol 'org-marker))
          (org-back-to-heading))
        (when (derived-mode-p 'org-mode)
          (let* ((context ;; Borrowed from org-open-at-point
                  ;; Only consider supported types, even if they are not the
                  ;; closest one.
                  (org-element-lineage (org-element-context)
                                       '(headline src-block link) t))
                 (type (org-element-type context))
                 (value (org-element-property :value context)))
            (cond ((eq type 'headline)
                   (cons 'org-heading (org-element-property :title context)))
                  ;; src-block and link can be handled by embark-org
                  )))))))

(defun my-embark-org-src-block-copy-noweb-reference (element)
  (kill-new (if (org-element-property element :parameters)
                (format "<<%s(%s)>>" (org-element-property element :name)
                        (org-element-property element :parameters))
              (format "<<%s>>" (org-element-property element :parameters)))))
(with-eval-after-load 'embark-org
  (keymap-set embark-org-src-block-map "N" #'my-embark-org-src-block-copy-noweb-reference))

(defun embark-which-key-indicator ()
  "An embark indicator that displays keymaps using which-key.
The which-key help message will show the type and value of the
current target followed by an ellipsis if there are further
targets."
  (lambda (&optional keymap targets prefix)
    (if (null keymap)
        (which-key--hide-popup-ignore-command)
      (which-key--show-keymap
       (if (eq (plist-get (car targets) :type) 'embark-become)
           "Become"
         (format "Act on %s '%s'%s"
                 (plist-get (car targets) :type)
                 (embark--truncate-target (plist-get (car targets) :target))
                 (if (cdr targets) "…" "")))
       (if prefix
           (pcase (lookup-key keymap prefix 'accept-default)
             ((and (pred keymapp) km) km)
             (_ (key-binding prefix 'accept-default)))
         keymap)
       nil nil t (lambda (binding)
                   (not (string-suffix-p "-argument" (cdr binding))))))))

(setq embark-indicators
      '(embark-which-key-indicator
        embark-highlight-indicator
        embark-isearch-highlight-indicator))

(defun embark-hide-which-key-indicator (fn &rest args)
  "Hide the which-key indicator immediately when using the completing-read prompter."
  (which-key--hide-popup-ignore-command)
  (let ((embark-indicators
         (remq #'embark-which-key-indicator embark-indicators)))
    (apply fn args)))

(with-eval-after-load 'embark
  (advice-add #'embark-completing-read-prompter
              :around #'embark-hide-which-key-indicator))

(setq ess-r-flymake-linters
      '("closed_curly_linter = NULL" "commas_linter = NULL"
        "commented_code_linter = NULL" "infix_spaces_linter = NULL"
        "line_length_linter = NULL" "object_length_linter = NULL"
        "object_name_linter = NULL" "object_usage_linter = NULL"
        "open_curly_linter = NULL" "pipe_continuation_linter = NULL"
        "single_quotes_linter = NULL" "spaces_inside_linter = NULL"
        "spaces_left_parentheses_linter = NULL" "trailing_blank_lines_linter = NULL"
        "trailing_whitespace_linter = NULL"
        "line_length_linter(length = 120L, ignore_string_bodies = FALSE)"
        "return_linter = NULL"))

(setq browse-url-browser-function 'browse-url-generic)
(setq browse-url-generic-program "firefox")

;; (defvar xah-replace-invisible-char-list nil
;; "A alist used by `xah-replace-invisible-char'.
;; Each element is (codepoint . nameString).
;; The codepoint is an integer.
;; The nameString is for documentation purposes.
;; ")

;; (setq
;;  xah-replace-invisible-char-list
;;  '(
;;    ;;

;;    (65279 . "ZERO WIDTH NO-BREAK SPACE")
;;    (8203 . "ZERO WIDTH SPACE")
;;    (8206 . "LEFT-TO-RIGHT MARK")
;;    (8207 . "RIGHT-TO-LEFT MARK")
;;    (8232 . "LINE SEPARATOR")
;;    (8233 . "PARAGRAPH SEPARATOR")
;;    (8238 . "RIGHT-TO-LEFT OVERRIDE")
;;    (8239 . "NARROW NO-BREAK SPACE")
;;    (8288 . "WORD JOINER")

;;    (65532 . "OBJECT REPLACEMENT CHARACTER")
;;    (65024 . "VARIATION SELECTOR-1")
;;    (65025 . "VARIATION SELECTOR-2")
;;    (65026 . "VARIATION SELECTOR-3")
;;    (65027 . "VARIATION SELECTOR-4")
;;    (65028 . "VARIATION SELECTOR-5")
;;    (65029 . "VARIATION SELECTOR-6")
;;    (65030 . "VARIATION SELECTOR-7")
;;    (65031 . "VARIATION SELECTOR-8")
;;    (65032 . "VARIATION SELECTOR-9")
;;    (65033 . "VARIATION SELECTOR-10")
;;    (65034 . "VARIATION SELECTOR-11")
;;    (65035 . "VARIATION SELECTOR-12")
;;    (65036 . "VARIATION SELECTOR-13")
;;    (65037 . "VARIATION SELECTOR-14")
;;    (65038 . "VARIATION SELECTOR-15")
;;    (65039 . "VARIATION SELECTOR-16")))

;; ;; "\ufeff\\|\u200b\\|\u200f\\|\u202e\\|\u200e\\|\ufffc\\|\ufe0f"

;; (defun xah-replace-invisible-char (&optional Confirm-p)
;;   "Query replace some invisible Unicode chars.
;; The chars replaced are from `xah-replace-invisible-char-list'.
;; Search begins at beginning of buffer. (respects `narrow-to-region')
;; When the command is done, call `exchange-point-and-mark' to go back to the original cursor position.
;; URL `http://xahlee.info/emacs/emacs/elisp_unicode_replace_invisible_chars.html'
;; Created: 2018-09-07
;; Version: 2024-12-07"
;;   (interactive (list t))
;;   (goto-char (point-min))
;;   (let ((case-replace nil)
;;         (case-fold-search nil)
;;         (xregex
;;          (regexp-opt
;;           (mapcar (lambda (x) (char-to-string (car x))) xah-replace-invisible-char-list)))
;;         xresult
;;         )
;;     (while (re-search-forward xregex nil t)
;;       (let (xcharId xname)
;;         (setq xcharId (string-to-char (match-string 0)))
;;         (setq xname (get-char-code-property xcharId 'name))
;;         (if Confirm-p
;;             (if (y-or-n-p (format "found 「%s」 codepoint 「%s」, position 「%s」, replace?" xname xcharId (point)))
;;                 (replace-match "")
;;               nil
;;               )
;;           (replace-match ""))
;;         (push (vector xname xcharId (or buffer-file-name (buffer-name)) (point)) xresult)
;;         (push-mark)
;;         (overlay-put (make-overlay (point) (progn (forward-word) (point))) 'face 'font-lock-warning-face)))
;;     (print "Done replace invisible chars or none.")
;;     xresult))


;; (use-package! auto-save-async
;;   :config
;;   (auto-save-async-mode 1))


;; (use-package! treesit-auto
;;   :config
;;   (setq treesit-auto-install 'prompt)
;;   (treesit-auto-add-to-auto-mode-alist 'all)
;;   (global-treesit-auto-mode))


;; Auto-Formatting
(use-package! format-all
  :preface
  (defun ian/format-code ()
    "Auto-format the whole buffer."
    (interactive)
    (if (derived-mode-p 'prolog-mode)
        (prolog-indent-buffer)
      (format-all-buffer)))
  :config
  (add-hook 'prog-mode-hook #'format-all-ensure-formatter))



(defun comment-delete (arg)
  "Delete the first comment on this line, if any.  Don't touch
the kill ring.  With prefix ARG, delete comments on that many
lines starting with this one."
  (interactive "P")
  (comment-normalize-vars)
  (dotimes (_i (prefix-numeric-value arg))
    (save-excursion
      (beginning-of-line)
      (let ((cs (comment-search-forward (line-end-position) t)))
        (when cs
          (goto-char cs)
          (skip-syntax-backward " ")
          (setq cs (point))
          (comment-forward)
          ;; (kill-region cs (if (bolp) (1- (point)) (point))) ; original
          (delete-region cs (if (bolp) (1- (point)) (point)))  ; replace kill-region with delete-region
          (indent-according-to-mode))))
    (if arg (forward-line 1))))

(defun comment-delete-dwim (beg end arg)
  "Delete comments without touching the kill ring.  With active
region, delete comments in region.  With prefix, delete comments
in whole buffer.  With neither, delete comments on current line."
  (interactive "r\nP")
  (let ((lines (cond (arg
                      (count-lines (point-min) (point-max)))
                     ((region-active-p)
                      (count-lines beg end)))))
    (save-excursion
      (when lines
        (goto-char (if arg (point-min) beg)))
      (comment-delete (or lines 1)))))


'(flymake-errline ((((class color)) (:underline "OrangeRed"))))
'(flymake-warnline ((((class color)) (:underline "yellow"))))

(use-package! colorful-mode
  :custom
  (colorful-use-prefix nil)
  ;; (colorful-only-strings 'only-prog)
  (css-fontify-colors nil)

  :config
  (global-colorful-mode t)
  (add-to-list 'global-colorful-modes '(prog-mode help-mode html-mode css-mode latex-mode helpful-mode text-mode)))


(use-package! fzf
  ;; :bind
  ;;   ;; Don'tforget to set keybinds!
  :config
  (setq fzf/args "-x --color bw --print-query --margin=1,0 --no-hscroll"
        fzf/executable "fzf"
        fzf/git-grep-args "-i --line-number %s"
        ;; command used for `fzf-grep-*` functions
        ;; example usage for ripgrep:
        ;; fzf/grep-command "rg --no-heading -nH"
        fzf/grep-command "grep -nrH"
        ;; If nil, the fzf buffer will appear at the top of the window
        fzf/position-bottom t
        fzf/window-height 15))


(setq grip-url-browser "firefox")

(defadvice! fix-ess-display-help (buff)
  :override #'ess-display-help
  (pop-to-buffer buff))


(after! ess
  (setq ess-r-flymake-lintr-cache nil)
  (add-hook! '+popup-mode-hook
    (setq display-buffer-alist
          (append `(("^\\*R Dired"
                     (display-buffer-reuse-window display-buffer-in-side-window)
                     (side . right)
                     (slot . -1)
                     (window-width . 0.33)
                     (reusable-frames . nil))
                    ("^\\*R"
                     (display-buffer-reuse-window display-buffer-at-bottom)
                     (window-width . 0.5)
                     (reusable-frames . nil))
                    ("^\\*Help"
                     (display-buffer-reuse-window display-buffer-in-side-window)
                     (side . right)
                     (slot . 1)
                     (window-width . 0.33)
                     (reusable-frames . nil)))
                  display-buffer-alist))))

(map! :after ess-help
      :map ess-help-mode-map
      :n "q" nil
      :n "ESC" nil)

(map! :after ess-rdired
      :map ess-rdired-mode-map
      :n "q" nil
      :n "ESC" nil)

(setq lsp-diagnostics-disabled-modes
      '(ess-mode))


(setq hippie-expand-try-functions-list
      '(try-expand-list
        try-expand-dabbrev-visible
        try-expand-dabbrev
        try-expand-all-abbrevs
        try-expand-dabbrev-all-buffers
        try-complete-file-name-partially
        try-complete-file-name
        try-expand-dabbrev-from-kill
        try-expand-whole-kill
        try-expand-line
        try-complete-lisp-symbol-partially
        try-complete-lisp-symbol))

(defun +he-subst-suffix-overlap (ins rem)
  "The longest suffix of the string INS that is a prefix of REM.
This is intended to be used when INS is a newly inserted string and REM is the
remainder of the line, to allow for handling potentially duplicated content."
  (let ((len (min (length ins) (length rem))))
    (while (and (> len 0)
                (not (eq 't (compare-strings ins (- len) nil rem 0 len))))
      (setq len (1- len)))
    len))

(defun +he-suffix-strip-a (args)
  "Filter ARG list for `he-substitute-string', truncating duplicated suffix.
ARGS is the raw argument list (STRING &optional TRANS-CASE)."
  (pcase-let* ((`(,ins &optional ,trans-case) args)
               (rem (save-excursion
                      (goto-char (marker-position he-string-end))
                      (buffer-substring-no-properties
                       (point) (line-end-position))))
               (ov (+he-subst-suffix-overlap ins rem)))
    (when (>= ov 0)
      (setq ins (substring ins 0 (- (length ins) ov))))
    (list ins trans-case)))

(advice-add #'he-substitute-string :filter-args #'+he-suffix-strip-a)

(setq elfeed-feeds
      '("https://this-week-in-rust.org/rss.xml"
        "http://feeds.bbci.co.uk/news/rss.xml"
        "http://planet.clojure.in/atom.xml"
        "https://rss.nytimes.com/services/xml/rss/nyt/World.xml"
        "https://rss.nytimes.com/services/xml/rss/nyt/Business.xml"
        "https://rss.nytimes.com/services/xml/rss/nyt/Technology.xml"
        "https://rss.nytimes.com/services/xml/rss/nyt/Science.xml"
        "https://rss.nytimes.com/services/xml/rss/nyt/Books/Review.xml"))

(with-eval-after-load 'elfeed
  (setq elfeed-search-filter "@1-week-ago +unread"))

(add-hook 'elfeed-search-mode-hook #'elfeed-update)

(use-package! org-pandoc-import :after org)

(use-package! smartparens
  :init
  (map! :map smartparens-mode-map
        "C-M-f" #'sp-forward-sexp
        "C-M-b" #'sp-backward-sexp
        "C-M-u" #'sp-backward-up-sexp
        "C-M-d" #'sp-down-sexp
        "C-M-p" #'sp-backward-down-sexp
        "C-M-n" #'sp-up-sexp
        "C-M-s" #'sp-splice-sexp
        "C-)" #'sp-forward-slurp-sexp
        "C-}" #'sp-forward-barf-sexp
        "C-(" #'sp-backward-slurp-sexp
        "C-M-)" #'sp-backward-slurp-sexp
        "C-M-)" #'sp-backward-barf-sexp))

(provide 'setup-utils)
;;; setup-utils.el ends here
