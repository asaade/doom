;;; lisp/setup-roam-templates.el --- Create some roam templaes  -*- lexical-binding: t; -*-


(setq org-roam-capture-templates
      '(("d" "default" plain
         "%?"
         :if-new (file+head "~/Dropbox/org/roam/main/${slug}.org"
                            "#+title: ${title}\n#+last_modified: []\n\n")
         :immediate-finish t
         :unnarrowed t)
        ("m" "main" plain
         "%?"
         :if-new (file+head "main/${slug}.org"
                            "#+title: ${title}\n")
         :immediate-finish t
         :unnarrowed t)
        ("p" "PM" plain
         "%?"
         :if-new (file+head "pm/${slug}.org"
                            "#+title: ${title}
#+author: Antonio Saade
#+date: [2024-01-07 dom]
#+last_modified:  2024/07/25 07:17
#+todo: TODO(t) PROG(p) REVW(r) BLOCK(b) | DONE(d)) CANCELED(c)

#+begin: clocktable :scope file :block thisweek :maxlevel 2 :step day :stepskip0 t
#+end:\n\n")
         :immediate-finish t
         :unnarrowed t)
        ("c" "curso" plain
         "%?"
         :if-new (file+head "curso/${slug}.org"
                            "#+title: ${title}
#+author: Antonio Saade
#+date: [2024-01-07 dom]
#+last_modified:  2024/01/14 15:23:54
:config:
#+language: es
#+options: toc:nil num:nil email:nil
#+options: reveal_embed_local_resources:nil
#+options: reveal_width:1400 reveal_height:1000
#+reveal_hlevel: 1
#+reveal_theme: serif
#+reveal_trans: slide
#+reveal_plugins: (highlight menu search)
#+startup: hideblocks contents
:end:
")
         :immediate-finish t
         :unnarrowed t)
        ("s" "saade.me" plain
         "%?"
         :if-new (file+head "saade.me/${slug}.org"
                            "#+title: ${title}
#+author: Antonio Saade
#+date: %u
#+last_modified:  2023/11/18 01:19:43
:SETTINGS:
#+subtitle:
#+description:
#+filetags:
#+roam_ref: [[id:5d0a5c99-bae1-4c5a-a647-952a6ce1f361][Cuentos]]
#+hugo_section: posts
#+hugo_categories: cuentos
#+hugo_draft: true
#+setupfile: ../setup.org
#+setupfile: ../setup-hugo.org
:END:
\n\n")
         :immediate-finish t
         :unnarrowed t)
        ("n" "saade.net" plain
         "%?"
         :if-new (file+head "saade.net/${slug}.org"
                            "#+title: ${title}
#+author: Antonio Saade
#+date: %u
#+last_modified:  2023/11/05
:SETTINGS:
#+subtitle:
#+description:
#+filetags:
#+hugo_section: posts
#+hugo_categories:
#+hugo_draft: true
#+setupfile: ../setup.org
#+setupfile: ../setup-hugo.org
:END:
\n\n")
         :immediate-finish t
         :unnarrowed t)
        ("a" "article" plain "%?"
         :if-new
         (file+head "articles/${title}.org" "#+title: ${title}\n#+filetags: :article:\n")
         :immediate-finish t
         :unnarrowed t)
        ;; ("l" "literature note" plain
        ;;      "%?"
        ;;      :target
        ;;      (file+head
        ;;       "%(expand-file-name (or citar-org-roam-subdir \"\") org-roam-directory)/${citar-citekey}.org"
        ;;       "#+title: ${citar-citekey} (${citar-date}). ${note-title}.\n#+created: %U\n#+last_modified: %U\n\n")
        ;;      :unnarrowed t)
        )

      ;; ("t" "Task" entry
      ;;  #'org-roam-capture--get-point
      ;;  "* TODO %?\n  %U\n  %a\n  %i"
      ;;  :file-name "Journal/%<%Y-%m-%d>"
      ;;  :olp ("Tasks")
      ;;  :empty-lines 1
      ;;  :head "#+title: %<%Y-%m-%d %a>\n\n[[roam:%<%Y-%B>]]\n\n")
      ;; ("p" "project" plain "* Goals\n\n%?\n\n* Tasks\n\n** TODO Add initial tasks\n\n* Dates\n\n"
      ;;  :if-new (file+head "%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+category: ${title}\n#+filetags: Project")
      ;;  :unnarrowed t)
      )


(provide 'setup-roam-templates)
;;; setup-roam-templates.el ends here
