;;; ~/Dropbox/doom/lisp/setup-calibre.el --- Configures access to Calibre books DB  -*- lexical-binding: t; -*-

(use-package! calibredb
  :commands calibredb
  :config
  (setq calibredb-root-dir "~/Calibre"
        calibredb-db-dir (expand-file-name "metadata.db" calibredb-root-dir)
        calibredb-id-width 6
        calibredb-tag-width 0
        calibredb-title-width 70
        calibredb-pubdate-width 6
        calibredb-comment-width 0))


(use-package! org-ref
  :after-call calibredb
  :config
  (setq org-ref-default-bibliography '("~/Dropbox/org/references/references.bib")
        calibredb-ref-default-bibliography "~/Dropbox/org/references/calibre.bib")
  (add-to-list 'bibtex-completion-bibliography calibredb-ref-default-bibliography)
  (setq org-ref-get-pdf-filename-function 'org-ref-get-mendeley-filename)
  ;; (setq org-ref-insert-cite-function
  ;;       (lambda ()
  ;;         (org-cite-insert nil)))
  )

(use-package! org-ref
  :after calibredb
  :config
  (setq org-ref-default-bibliography '("~/Dropbox/org/references/references.bib")
        calibredb-ref-default-bibliography "~/Dropbox/org/references/calibre.bib")
  (add-to-list 'org-ref-default-bibliography calibredb-ref-default-bibliography)
  (setq org-ref-get-pdf-filename-function 'org-ref-get-mendeley-filename)
)



  (provide 'setup-calibre)
;;; setup-calibre.el ends here
