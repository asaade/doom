;;; lisp/setup-org.el --- Org mode configuration -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:
;;;

(defun skx/update-org-modified-property ()
  "Update '#+LAST_MODIFIED' with the current date/time."
  (interactive)
  (save-excursion
    (widen)
    (goto-char (point-min))
    (let ((case-fold-search t))
      (when (re-search-forward "^#\\+last_modified:" nil t)
        (delete-region (line-beginning-position) (line-end-position))
        (insert (concat "#+last_modified: "
                        (format-time-string " %Y/%m/%d %H:%M")))))))

;; https://sachachua.com/dotemacs/index.html#org8d18f7e
(defun my-org-convert-region-from-markdown (beg end)
  (interactive "r")
  (shell-command-on-region beg end "pandoc -t org" nil t))

(defun org-syntax-convert-keyword-case-to-lower ()
  "Convert all #+KEYWORDS to #+keywords."
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (let ((count 0)
          (case-fold-search nil))
      (while (re-search-forward "^[ \t]*#\\+[A-Z_]+" nil t)
        (unless (string-match-p "RESULTS" (match-string 0))
          (replace-match (downcase (match-string 0)) t)
          (setq count (1+ count))))
      (message "Replaced %d occurances" count))))

(add-hook! 'org-mode-hook
  (add-hook 'before-save-hook #'org-syntax-convert-keyword-case-to-lower nil t)
  (add-hook 'before-save-hook #'skx/update-org-modified-property nil t))


(setq org-confirm-babel-evaluate nil
      org-edit-src-content-indentation 4
      org-edit-src-persistent-message nil
      org-export-allow-bind-keywords t
      org-export-time-stamp-file t
      org-export-with-date nil
      org-export-with-email nil
      org-export-with-sub-superscripts '{}
      org-export-with-toc nil
      org-fold-catch-invisible-edits 'show
      org-fontify-quote-and-verse-blocks t
      org-fontify-whole-block-delimiter-line t
      org-footnote-auto-label t
      org-indirect-buffer-display 'other-window
      org-insert-heading-respect-content t
      org-link-descriptive t
      org-list-allow-alphabetical t
      org-num-max-level 3
      org-preview-latex-image-directory "/home/asaade/tmp/ltximg"
      org-startup-with-inline-images 'display-graphic-p
      org-startup-with-latex-preview t
      org-return-follows-link t
      org-special-ctrl-a/e t
      org-special-ctrl-k t
      ;; org-src-preserve-indentation t
      org-src-tab-acts-natively t
      org-src-window-setup 'current-window
      org-startup-folded 'content
      org-startup-indented t
      ;; org-tags-column 0
      org-fontify-emphasized-text t
      org-src-fontify-natively t
      org-catch-invisible-edits 'error
      ;; org-cycle-separator-lines 2
      org-image-actual-width 480
      ;; org-hide-emphasis-markers t)
      )

;; Numbered equations all have (1) as the number for fragments with vanilla
;; org-mode. This code injects the correct numbers into the previews so they
;; look good.

(defun scimax-org-renumber-environment (orig-func &rest args)
  "Inject numbers in LaTeX fragment previews using ORIG-FUNC."
  (let ((results '())
        (counter -1)
        (numberp))
    (setq results (cl-loop for (begin env) in
                           (org-element-map (org-element-parse-buffer) 'latex-environment
                             (lambda (env)
                               (cons
                                (org-element-property :begin env)
                                (org-element-property :value env))))
                           collect
                           (cond
                            ((and (string-match "\\\\begin{equation}" env)
                                  (not (string-match "\\\\tag{" env)))
                             (cl-incf counter)
                             (cons begin counter))
                            ((string-match "\\\\begin{align}" env)
                             (prog2
                                 (cl-incf counter)
                                 (cons begin counter)
                               (with-temp-buffer
                                 (insert env)
                                 (goto-char (point-min))
                                 ;; \\ is used for a new line. Each one leads to a number
                                 (cl-incf counter (count-matches "\\\\$"))
                                 ;; unless there are nonumbers.
                                 (goto-char (point-min))
                                 (cl-decf counter (count-matches "\\nonumber")))))
                            (t
                             (cons begin nil)))))

    (when (setq numberp (cdr (assoc (point) results)))
      (setf (car args)
            (concat
             (format "\\setcounter{equation}{%s}\n" numberp)
             (car args)))))
  (apply orig-func args))


(defun scimax-toggle-latex-equation-numbering ()
  "Toggle whether LaTeX fragments are numbered."
  (interactive)
  (if (not (get 'scimax-org-renumber-environment 'enabled))
      (progn
        (advice-add 'org-create-formula-image :around #'scimax-org-renumber-environment)
        (put 'scimax-org-renumber-environment 'enabled t)
        (message "Latex numbering enabled"))
    (advice-remove 'org-create-formula-image #'scimax-org-renumber-environment)
    (put 'scimax-org-renumber-environment 'enabled nil)
    (message "Latex numbering disabled.")))

(advice-add 'org-create-formula-image :around #'scimax-org-renumber-environment)
(put 'scimax-org-renumber-environment 'enabled t)


(defun zz/org-reformat-buffer ()
  (interactive)
  (when (y-or-n-p "Really format current buffer? ")
    (let ((document (org-element-interpret-data (org-element-parse-buffer))))
      (erase-buffer)
      (insert document)
      (goto-char (point-min)))))

(require 'cl-lib)
(require 'org-element)

(defun org-element-parse-headline (&optional granularity visible-only)
  "Parse current headline.
GRANULARITY and VISIBLE-ONLY are like the args of `org-element-parse-buffer'."
  (let ((level (org-current-level)))
    (org-element-map
        (org-element-parse-buffer granularity visible-only)
        'headline
      (lambda (el)
        (and
         (eq (org-element-property :level el) level)
         (<= (org-element-property :begin el) (point))
         (<= (point) (org-element-property :end el))
         el))
      nil 'first-match 'no-recursion)))


;; * tooltips on footnotes
(defun scimax-footnote-reference-tooltip (_win _obj position)
  "Get footnote contents."
  (save-excursion
    (goto-char position)
    (or
     (nth 3 (org-footnote-get-definition
             (org-element-property :label (org-element-context))))
     "No footnote content found.")))


(defun scimax-footnote-tooltip (limit)
  "Add text properties for footnotes.
This is used as :override advice on `org-activate-footnote-links'."
  (let ((fn (org-footnote-next-reference-or-definition limit)))
    (when fn
      (let* ((beg (nth 1 fn))
             (end (nth 2 fn))
             (label (car fn))
             (referencep (/= (line-beginning-position) beg)))
        (when (and referencep (nth 3 fn))
          (save-excursion
            (goto-char beg)
            (search-forward (or label "fn:"))
            (org-remove-flyspell-overlays-in beg (match-end 0))))
        (add-text-properties beg end
                             (list 'mouse-face 'highlight
                                   'keymap org-mouse-map
                                   'help-echo
                                   ;; this is the modification to get the tooltips to show
                                   (if referencep #'scimax-footnote-reference-tooltip
                                     ;; I don't know what would make sense here,
                                     ;; so we leave a string
                                     "Footnote definition")
                                   'font-lock-fontified t
                                   'font-lock-multiline t
                                   'face 'org-footnote))))))

(advice-add 'org-activate-footnote-links :override 'scimax-footnote-tooltip)

(use-package! scimax-ob-flycheck)

(setq org-latex-logfiles-extensions '("lof" "lot" "tex~" "aux" "idx" "log" "out" "toc" "nav" "snm"
                                      "vrb" "fdb_latexmk" "blg" "brf" "fls" "xml" "bcf" "entoc"
                                      "ps" "spl" "bbl" "thd" "spl" "bbl" "xmpi" "run.xml" "bcf" "acn"
                                      "acr" "alg" "glg" "gls" "ist" "thm"))
(setq org-latex-remove-logfiles t)

(use-package! ox-altacv)

(after! org-re-reveal
  (add-to-list 'org-re-reveal-plugin-config '(menu "RevealMenu" "plugin/menu/menu.js"))
  (setq org-re-reveal-theme "night"
        org-re-reveal-transition "slide"
        org-re-reveal-plugins '(markdown notes math search zoom)))

(setq org-babel-default-header-args:R
      '((:session . "*my session-r*")
        (:results . "value replace")
        (:exports . "results")
        (:colnames . "yes")
        (:cache . "yes")
        (:noweb . "no")
        (:hlines . "yes")
        (:tangle . "no")
        (:comments . "link")))

(setq org-babel-default-header-args:python
      '((:session . "*my session-python*")
        (:results . "value replace")
        (:exports . "results")
        (:colnames . "yes")
        (:cache . "no")
        (:noweb . "no")
        (:hlines . "yes")
        (:tangle . "yes")
        (:comments . "link")))

(setq org-babel-default-header-args
      '((:session . "*my session*")
        (:results . "value replace")
        (:exports . "results")
        (:colnames . "yes")
        (:cache . "no")
        (:noweb . "yes")
        (:hlines . "yes")
        (:tangle . "no")
        (:comments . "link")))

(setq org-latex-default-table-environment "longtable"
      org-latex-remove-logfiles t
      org-latex-compiler "lualatex"
      ;; org-latex-pdf-process (list "texliveonfly.py %f"))
      org-latex-pdf-process (list "latexmk -pdflatex='lualatex -synctex=1 -shell-escape -interaction nonstopmode' -shell-escape -pdf -bibtex -f -output-directory=%o %f"))

(setq org-preview-latex-default-process 'dvisvgm)

;; https://github.com/emacsmirror/org-contrib
(use-package! ox-extra
  :after org
  :config
  (ox-extras-activate '(latex-header-blocks ignore-headlines)))

(use-package! org-transclusion
  :after org
  :config
  (map!
   :map global-map "C-t" #'org-transclusion-add
   :leader
   :prefix "n"                          ;
   :desc "Org Transclusion Mode" "t" #'org-transclusion-mode)
  (setq  org-transclusion-include-first-section nil
         org-transclusion-add-all-on-activate nil))

;; Org-appear and other Org-related packages
(use-package! org-appear
  :after org
  :config
  (setq org-appear-autolinks t
        org-appear-autoentities t
        org-appear-autoemphasis t
        org-appear-autokeywords t
        org-hide-emphasis-markers t))

(use-package! org-fragtog)

(add-hook 'org-mode-hook 'org-fragtog-mode)


(use-package! citar
  :after org
  :custom
  (org-cite-global-bibliography
   (directory-files (concat org-directory "/references") t "^[A-Z|a-z|0-9].+.bib$"))
  (citar-bibliography org-cite-global-bibliography)
  (citar-notes-paths (list (concat org-directory "/references/notes/")))
  ;; (citar-library-paths '("~/Zotero/storage/" "~/Calibre/"))
  (org-cite-csl-styles-dir "~/dev/csl-styles")
  (org-cite-csl-locales-dir "~/dev/csl-styles/locales")
  (org-cite-insert-processor 'citar)
  (org-cite-follow-processor 'citar)
  (org-cite-activate-processor 'citar)
  (citar-at-point-function 'embark-act)
  :config
  (map!
   :map org-mode-map
   "C-c b" #'org-cite-insert
   :leader
   :prefix "n"
   :desc "Org insert citation" "t" #'citar))

(use-package! citar-org-roam
  :after (citar org-roam)
  :config (citar-org-roam-mode))

(after! ox-latex
  ;; Add KOMA-scripts classes to org export
  (add-to-list 'org-latex-classes
               '("koma-letter" "\\documentclass[paper=letter]{scrletter}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

  (add-to-list 'org-latex-classes
               '("koma-article" "\\documentclass[11pt,paper=letter]{scrartcl}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

  (add-to-list 'org-latex-classes
               '("koma-report" "\\documentclass[11pt,paper=letter]{scrreprt}"
                 ("\\part{%s}" . "\\part*{%s}")
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("koma-book" "\\documentclass[11pt,paper=letter]{scrbook}"
                 ("\\part{%s}" . "\\part*{%s}")
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("classic" "\\RequirePackage{silence} % :-\\
    \\WarningFilter{scrbook}{Usage of package `titlesec'}
    \\WarningFilter{titlesec}{Non standard sectioning command detected}
\\documentclass[11pt,letterpaper,footinclude,headinclude,oneside,open=right]{scrbook}
\\usepackage[T1]{fontenc}
\\usepackage{lipsum}
\\usepackage[parts,eulerchapternumbers=true, style=linedheaders, beramono=false,eulermath=true]{classicthesis}
"
                 ;; ("\\part{%s}" . "\\part*{%s}")
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("classic-article" "\\RequirePackage{silence} % :-\\
    \\WarningFilter{article}{Usage of package `titlesec'}
    \\WarningFilter{titlesec}{Non standard sectioning command detected}
\\documentclass[11pt,letterpaper,footinclude,headinclude,oneside,open=right]{article}
\\usepackage[T1]{fontenc}
\\usepackage{lipsum}
\\usepackage[parts,nochapters, style=linedheaders, beramono=false,eulermath=true]{classicthesis}
"
                 ;; ("\\part{%s}" . "\\part*{%s}")
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("springer-mono"
                 "\\documentclass[letter,graybox,envcountchap,sectrefs]{svmono}
                [PACKAGES]"

                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("tufte-book"
                 "\\documentclass[letter,graybox,envcountchap,sectrefs]{tufte-book}
                [PACKAGES]"

                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("springer-modern"
                 "\\documentclass[letter, 10pt, twoside, openright]{book}
                 \\usepackage{modernmono2}
                [PACKAGES]
                 \\usepackage{titlesec}
                \\newcommand{\\sectionbreak}{\\clearpage}
                \\newcommand{\\subsectionbreak}{\\clearpage}"

                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("memoir"
                 "\\documentclass{memoir}
               \\usepackage[letterpaper, mag=1200, truedimen, width=4.0in, left=2.5in, top=0.8in, bottom=0.8in]{geometry}"
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("kao"
                 "\\documentclass[letter, fontsize=10pt, twoside=false,
        %open=any, % If twoside=true, uncomment this to force new chapters to start on any page, not only on right (odd) pages
        %chapterentrydots=true, % Uncomment to output dots from the chapter name to the page number in the table of contents
        numbers=noenddot, % Comment to output dots after chapter numbers; the most common values for this option are: enddot, noenddot and auto (see the KOMAScript documentation for an in-depth explanation)
        fontmethod=tex,]{kaobook}
% Load the bibliography package
\\usepackage{kaobiblio}
% Load mathematical packages for theorems and related environments
\\usepackage[framed=true]{kaotheorems}
% Load the package for hyperreferences
\\usepackage{kaorefs}
\\graphicspath{{static/images/}{images/}} % Paths in which to look for images
\\makeindex[columns=3, title=Alphabetical Index, intoc] % Make LaTeX produce the files required to compile the index
\\makeglossaries % Make LaTeX produce the files required to compile the glossary
% \\input{glossary.tex} % Include the glossary definitions
\\makenomenclature % Make LaTeX produce the files required to compile the nomenclature
[PACKAGES]
"
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))


  (add-to-list 'org-latex-classes
               '("springer-report"
                 "\\documentclass[letter, graybox,envcountchap,sectrefs]{svmono}"

                 ("\\chapter{%s}" . "\\section*{%s}")
                 ("\\section{%s}" . "\\subsection*{%s}")
                 ("\\subsection{%s}" . "\\subsubsection*{%s}")))

  (add-to-list 'org-latex-classes
               '("springer-enhanced"
                 "\\documentclass[letter,graybox,envcountchap,sectrefs]{SVMonoEnhanced}
                [PACKAGES]"
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")))

  (setq org-latex-default-class "koma-article")
  )

;; Hugo Export Functions
(after! ox-hugo
  (defun compile-dir-org ()
    "Publish all Org files in a directory."
    (interactive)
    (save-excursion
      (mapc
       (lambda (file)
         (with-current-buffer (find-file-noselect file)
           (org-hugo-export-to-md)))
       (file-expand-wildcards "*.org"))))

  (defun deploy-saade-me ()
    "Publish all Org files in a directory."
    (interactive)
    (start-process-shell-command "publish" nil "~/.bin/deploy-saade.me.sh")))

;; Org-roam Templates
(setq org-roam-capture-templates
      '(("d" "default" plain
         "%?"
         :if-new (file+head "~/Dropbox/org/roam/main/%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n#+last_modified: []\n\n")
         :immediate-finish t
         :unnarrowed t)
        ("x" "Slipbox" entry  (file "~/Dropbox/org/inbox.org")
         "* %?\n")
        ("m" "main" plain
         "%?"
         :if-new (file+head "main/%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}\n")
         :immediate-finish t
         :unnarrowed t)
        ("c" "curso" plain
         "%?"
         :if-new (file+head "curso/%<%Y%m%d%H%M%S>-${slug}.org"
                            "#+title: ${title}
#+author: Antonio Saade
#+date: [2024-01-07 dom]
#+last_modified:  2026/03/21 07:53
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
:end:")
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
:END:")
         :immediate-finish t
         :unnarrowed t)
        ("r" "reference" plain "%?"
         :if-new
         (file+head "reference/${title}.org" "#+title: ${title}\n")
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
:END:")
         :immediate-finish t
         :unnarrowed t)
        ("a" "article" plain "%?"
         :if-new
         (file+head "articles/${title}.org" "#+title: ${title}\n#+filetags: :article:\n")
         :immediate-finish t
         :unnarrowed t)))

(setq org-roam-mode-sections
      (list #'org-roam-backlinks-section
            #'org-roam-reflinks-section))

(add-hook 'org-roam-buffer-postrender-functions #'magit-section-show-level-2)

(defun org-rename-to-new-title ()
  "Rename current org-roam file to match its title slug."
  (when-let*
      ((old-file (buffer-file-name))
       (is-roam-file (org-roam-file-p old-file))
       (file-node (save-excursion
                    (goto-char 1)
                    (org-roam-node-at-point)))
       (file-name  (file-name-base (org-roam-node-file file-node)))
       (file-time  (or (and (string-match "\\`\\([0-9]\\{14\\}\\)-" file-name)
                            (concat (match-string 1 file-name) "-"))
                       ""))
       (slug (org-roam-node-slug file-node))
       (new-file (expand-file-name (concat file-time slug ".org")))
       (different-name? (not (string-equal old-file new-file))))

    (rename-buffer new-file)
    (rename-file old-file new-file)
    (set-visited-file-name new-file)
    (set-buffer-modified-p nil)))

(add-hook! 'org-roam-mode-hook
  (add-hook 'after-save-hook #'org-rename-to-new-title nil t))

(add-to-list 'display-buffer-alist
             '("\\*org-roam\\*"
               (display-buffer-in-side-window)
               (side . right)
               (slot . 0)
               (window-width . 0.33)
               (window-parameters . ((no-other-window . t)
                                     (no-delete-other-windows . t)))))


(setq ob-mermaid-cli-path "/usr/bin/mmdc")

(plist-put! org-format-latex-options
            :scale 1.2
            :background "Transparent"
            :html-scale 1.2
            :html-background "Transparent")


(defun ar/ndjson-to-org-table (ndjson)
  "Convert NDJSON log string to an Org mode table."
  (let* ((rows (mapcar #'json-read-from-string (split-string ndjson "\n" t)))
         (fields (read-string "Fields: " (mapconcat (lambda (x) (symbol-name (car x))) (car rows) " ")))
         (header (split-string fields)))
    (orgtbl-to-orgtbl
     (append
      (list header)
      '(hline)
      (mapcar (lambda (obj)
                (mapcar (lambda (key)
                          (alist-get (intern key) obj))
                        header))
              rows)) nil)))

(defun ar/insert-ndjson-org-table ()
  "Convert ndjson kill ring or file to an org table and insert."
  (interactive)
  (save-excursion
    (condition-case nil
        (progn
          (insert (ar/ndjson-to-org-table (car kill-ring)))
          (org-table-align))
      (error
       (let ((file (read-file-name "NDJSON file: ")))
         (insert (ar/ndjson-to-org-table
                  (with-temp-buffer
                    (insert-file-contents file)
                    (buffer-string))))
         (org-table-align))))))

(defun adviced:org-yank (orig-fun &rest r)
  "Advice `adviced:org-yank' to align tables (ORIG-FUN and R)."
  (apply orig-fun r)
  (when (and (org-at-table-p)
             org-table-may-need-update)
    (org-table-align)))

(advice-add #'org-yank
            :around
            #'adviced:org-yank)

(setopt global-corfu-modes
        '((not erc-mode circe-mode help-mode gud-mode vterm-mode org-mode markdown-mode text-mode) t))

(setq org-use-speed-commands
      (lambda ()
        (and (looking-at org-outline-regexp)
             (looking-back "^\\**" (line-beginning-position)))))

(add-hook! org-mode (electric-indent-local-mode -1))

(provide 'setup-org)
;;; setup-org.el ends here
