;;; $DOOMDIR/lisp/setup-hugo.el -*- lexical-binding: t; -*-

(defun my-hugo-export ()
   (org-hugo-export-wim-to-md-after-save))

(after! ox-hugo
  (setq org-hugo-link-desc-insert-type t
        org-hugo-use-code-for-kbd t
        org-hugo-paired-shortcodes "sidenote marginnote epigraph blockquote")

  (add-to-list 'org-hugo-special-block-type-properties '("sidenote" . (:trim-pre t :trim-post t)))
  (add-to-list 'org-hugo-special-block-type-properties '("marginnote" . (:trim-pre t :trim-post t)))

  (defun compile-dir-org ()
    "Publish all org files in a directory"
    (interactive)
    (save-excursion
      (mapc
       (lambda (file)
         (with-current-buffer
             (find-file-noselect file)
           (org-hugo-export-to-md)))
       (file-expand-wildcards  "*.org"))))

  (defun deploy-saade-me ()
    "Publish all org files in a directory"
    (interactive)
    (start-process-shell-command "publish" nil "~/.bin/deploy-saade.me.sh"))

  ;; (defun deploy-saade-net ()
  ;;   "Publish all org files in a directory"
  ;;   (interactive)
  ;;   (start-process-shell-command "publish" nil "~/.bin/deploy-saade.net.sh"))

  (defun deploy-tufte-net ()
    "Publish all org files in a directory"
    (interactive)
    (start-process-shell-command "publish" nil "~/.bin/deploy-saade.tufte.sh")))


(provide 'setup-hugo)
