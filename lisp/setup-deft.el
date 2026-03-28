;;; $DOOMDIR/lisp/setup-deft.el --- Main configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;; ========================================================

(setq deft-default-extension "org"
      deft-extensions '("org")
      deft-recursive nil
      deft-use-filename-as-title nil
      deft-use-filter-string-for-filename t
      deft-file-naming-rules '((noslash . "-")
                               (nospace . "-")
                               (case-fn . downcase))
      deft-separator " "
      deft-time-format " %d %b %Y")

(defun deft-print-header ()
  (force-mode-line-update))

(defun org-open-file-with-emacs (path)
  (org-open-file path t))

(defun deft-setup ()
  ;;(face-remap-add-relative 'hl-line :inherit 'nano-salient-i)
  (set-window-fringes nil 0 1)
  (set-default 'truncate-lines t))

(add-hook 'deft-mode-hook #'deft-setup)

(defun my/deft-parse-summary (orig-fun contents title)
  "Filter deft summary in order to extract the first dot
terminated sentence and add tags if any."
  (let ((summary (apply orig-fun (list contents title)))
        (tags nil))
    (when (and (stringp contents)
               (string-match "#\\+TAGS:\\(.*\\)$" contents))
      (setq tags (split-string (string-trim (match-string 1 contents))
                               "[ ,]")))
    (if (and (stringp summary)
             (string-match "\\(.*?\\)\\. " summary))
        (concat
         (when tags
           (concat (propertize (car tags)
                               'display (svg-tag-make (car tags)
                                                      ;; :face 'nano-popout
                                                      :inverse t))
                   " "))
         (match-string 1 summary))
      summary)))

(advice-add 'deft-parse-summary :around #'my/deft-parse-summary)

(defun deft-note-toggle-keywords ()
  "Toggle visibility of all keywords."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (re-search-forward "^\\(#\\+.*\\)$" nil t)
    (if (get-text-property (match-beginning 1) 'display)
        (deft-note-show-keywords)
      (deft-note-hide-keywords))))

(defun deft-note-hide-keywords ()
  "Hide all keywords."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^\\(#\\+.*\\)$" nil t)
      ;; (message (format "Hiding keyword %s" (match-string 1)))
      (put-text-property
       (match-beginning 1) (+ (match-end 1) 1) 'display ""))))

(defun deft-note-show-keywords ()
  "Show all keywords."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward "^\\(#\\+.*\\)$" nil t)
      ;; (message (format "Showing keyword %s" (match-string 1)))
      (remove-text-properties
       (match-beginning 1) (+ (match-end 1) 1) '(display)))))

(defun deft-note-get-keyword (keyword)
  "Get the value of a KEYWORD"
  (interactive)
  (let ((case-fold-search t)
        (re (format "^#\\+%s:[ \t]+\\([^\t\n]+\\)" keyword)))
    (if (save-excursion (or (re-search-forward re nil t)
                            (re-search-backward re nil t)))
        (substring-no-properties (match-string 1)))))

(defun deft-note-set-keyword (keyword value)
  "Set the VALUE of KEYWORD, creates it if absent."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (if (deft-note-get-keyword keyword)
        (replace-match value t nil nil 1)
      (insert (format "#+%s: %s\n" keyword value)))))

(defun my/deft-open-file ()
  "Setup note modes and ask for a title if the file does not exist."
  (when (= (buffer-size (current-buffer)) 0)
    (setq title (read-from-minibuffer "Note title: "))
    (deft-note-set-keyword "DATE" (format-time-string "[%Y-%m-%d %a]"))
    (deft-note-set-keyword "TITLE" (if (> (length title) 0)
                                       title
                                     "New note"))
    (org-mode)
    (org-indent-mode)
    (visual-line-mode)))

(add-hook 'deft-open-file-hook 'my/deft-open-file)

(provide 'setup-deft)
;;; setup-deft.el ends here
