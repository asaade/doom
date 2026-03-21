;;; lisp/setup-multimedia.el --- Add multimedia capacities -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:
;;;

;;; https://sachachua.com/dotemacs/index.html#multimedia

(setq image-use-external-converter t)

(defun my-filename-timestamp (file)
  (setq file (replace-regexp-in-string "^screen-" "" (file-name-base file)))
  (cond
   ((string-match
     "\\([0-9][0-9][0-9][0-9]\\)_?\\([0-9][0-9]\\)_?\\([0-9][0-9]\\)_\\([0-9][0-9]\\)_?\\([0-9][0-9]\\)_?\\([0-9][0-9]\\)"
     file)
    (date-to-time (format "%s-%s-%s %s:%s:%s"
                          (match-string 1 file)
                          (match-string 2 file)
                          (match-string 3 file)
                          (match-string 4 file)
                          (match-string 5 file)
                          (match-string 6 file))))
   (t
    (time-add (date-to-time (format "%s %s" (substring file 0 10) (substring file 11 19)))
              (float-time (/ (string-to-number (substring file 20 23)) 1000.0))))))

(cl-assert
 (string= (format-time-string "test-%F-%T-%3N" (my-filename-timestamp "screen-2024-09-20-13:18:08-024.png"))
          "test-2024-09-20-13:18:08-024")
 (string= (format-time-string "test-%F-%T-%3N" (my-filename-timestamp "screen-2024-09-20-13_1808-024.png"))
          "test-2024-09-20-13:18:08-024"))


(defun my-ffmpeg-save-last-frame-as-image (input-file output-image)
  (interactive "FInput: \nFOutput: ")
  (let ((args (list
               "-sseof" "-2"
               "-i"
               (expand-file-name input-file)
               "-update"
               "1"
               "-q:v"
               "1"
               "-y"
               (expand-file-name output-image))))
    (with-current-buffer (get-buffer-create "*ffmpeg*")
      (insert "\nffmpeg "
              (mapconcat #'shell-quote-argument args " ") "\n")
      (apply 'call-process "ffmpeg" nil t nil args))))

(defun my-subed-interleave-image-links (dir &optional offset-ms)
  (interactive (list (read-file-name "Directory: ")
                     (if current-prefix-arg (read-number "Offset (ms): "))))
  (setq offset-ms (or offset-ms 0))
  (let* ((start-of-recording (my-filename-timestamp (buffer-file-name)))
         (subtitles (subed-subtitle-list))
         (end-of-recording
          (time-add start-of-recording
                    (seconds-to-time
                     (/
                      (elt (car (last subtitles)) 2)
                      1000.0))))
         (files
          (sort
           (seq-keep
            (lambda (f)
              (let ((time (my-filename-timestamp f)))
                (when (and
                       (not (time-less-p time start-of-recording))
                       (not (time-less-p end-of-recording time)))
                  (cons
                   ;; ms
                   (* 1000 (float-time (time-subtract time start-of-recording)))
                   f))))
            (directory-files dir t "20250123.*\\.\\(jpg\\|png\\|svg\\|webm\\)"))
           :key 'car)))
    ;; Now I have the cues and the file timestamps.
    ;; Do I want to add the comments to the current file or go streak to breaking it out?
    ;; Let's break it out into a different buffer.
    (save-excursion
      (goto-char (point-min))
      (unless (subed-subtitle-msecs-start) (subed-forward-subtitle-time-start))
      (dolist (cue subtitles)
        (when (and files (>= (+ offset-ms (elt cue 1)) (caar files)))
          (let ((link (org-link-make-string (concat "file:" (cdar files)))))
            (setf (elt cue 4)
                  (if (elt cue 4)
                      (concat (elt cue 4) "\n" link)
                    link))
            (subed-set-subtitle-comment (elt cue 4)))
          (pop files))
        (subed-forward-subtitle-time-start)))
    (with-current-buffer (get-buffer-create "*interleaved*")
      (erase-buffer)
      (org-mode)
      (insert (subed-subtitle-list-text subtitles t))
      (goto-char (point-min))
      (switch-to-buffer (current-buffer)))))

(defun my-subed-interleave-calculate-offset (filename)
  (interactive "FFile: ")
  (let ((start-of-recording (my-filename-timestamp (buffer-file-name)))
        (file-timestamp (my-filename-timestamp filename)))
    (message "%d"
             (- (* 1000.0
                   (time-to-seconds (time-subtract file-timestamp start-of-recording)))
                (subed-subtitle-msecs-start)))))

(defun my-split-at-words ()
  (interactive)
  (while (not (eobp))
    (recenter)
    (remove-overlays (point-min) (point-max) 'my-split t)
    (save-excursion
      (forward-word 3)
      (dotimes (n 10)
        (let* ((word-start (point))
               (word-end (progn (skip-syntax-forward "^ ") (point)))
               (overlay (make-overlay word-start word-end)))
          (overlay-put overlay 'my-split t)
          (overlay-put overlay 'split-num n)
          (overlay-put overlay 'evaporate t)
          (overlay-put overlay 'before-string (propertize (format "%s" n)
                                                          'face '(:foreground "white"
                                                                  :background "blue")))

          (skip-syntax-forward " ")
          )))
    (let* ((input (read-char "Split: "))
           (num (unless (= input 13)    ; enter
                  (string-to-number (char-to-string input))))
           (match (when num (seq-find (lambda (ov)
                                        (and (overlay-get ov 'split-num)
                                             (= (overlay-get ov 'split-num) num)))
                                      (overlays-in (point-min) (point-max))))))
      (if match
          (progn
            (goto-char (overlay-start match))
            (skip-syntax-backward " ")
            (delete-region (point) (overlay-start match))
            (insert "\n"))
        (forward-word 7)))))

(defun my-split-clear-overlays ()
  (interactive)
  (remove-overlays (point-min) (point-max) 'my-split t))

(defun my-split-sentence-and-capitalize ()
  (interactive)
  (delete-char 1)
  (insert ".")
  (capitalize-word 1))

(defun my-split-sentence-delete-word-and-capitalize ()
  (interactive)
  (delete-char 1)
  (insert ".")
  (kill-word 1)
  (capitalize-word 1))

(defun my-delete-word-and-capitalize ()
  (interactive)
  (skip-syntax-backward "w")
  (kill-word 1)
  (capitalize-word 1))

(defun my-emms-player-mplayer-set-speed (speed)
  "Depends on mplayer's -slave mode"
  (interactive "MSpeed: ")
  (process-send-string emms-player-simple-process-name
                       (format "speed_set %s\n" speed)))

(defvar my-emms-player-mplayer-speed-increment 0.1)

(defun my-emms-player-mplayer-speed-up ()
  "Depends on mplayer's -slave mode"
  (interactive)
  (process-send-string emms-player-simple-process-name
                       (format "speed_incr %f\n" my-emms-player-mplayer-speed-increment)))

(defun my-emms-player-mplayer-slow-down ()
  "Depends on mplayer's -slave mode"
  (interactive)
  (process-send-string emms-player-simple-process-name
                       (format "speed_incr %f\n" (- 0 my-emms-player-mplayer-speed-increment))))


(defun my-subed-remove-whisperx-underlines ()
  (interactive)
  (let (results)
    (dolist (cue (subed-subtitle-list))
      (let ((text (replace-regexp-in-string "</?u>" "" (elt cue 3))))
        (if (and results (string= text (elt (car results) 3)))
            (setf (elt (car results) 2) (elt cue 2))
          (setf (elt cue 3) text)
          (push cue results))))
    (goto-char (point-min))
    (subed-forward-subtitle-start-pos)
    (delete-region (point) (point-max))
    (subed-append-subtitle-list (reverse results))))

(defun my-subed-move-succeeding-subtitles-based-on-mpv ()
  "Move current and succeeding subtitles so that current starts at MPV playing position."
  (interactive)
  (if subed-mpv-playback-position
      (subed-move-subtitles
       (- subed-mpv-playback-position (subed-subtitle-msecs-start))
       (point) (point-max))
    (error "Need playback position.")))

(defun my-subed-check-random ()
  (interactive)
  (let* ((list (subed-subtitle-list))
         (pos (random (length list))))
    (subed-jump-to-subtitle-id
     (subed-msecs-to-timestamp (elt (elt list pos) 1)))
    (subed-mpv-jump-to-current-subtitle)
    (subed-mpv-unpause)))

(defun my-subed-get-region-start-stop (beg end)
  (interactive "r")
  (cons (save-excursion
          (goto-char (min beg end))
          (subed-subtitle-msecs-start))
        (save-excursion
          (goto-char (max beg end))
          (subed-subtitle-msecs-stop))))

(defun my-extend-file-name (original name &optional extension)
  "Add NAME to the end of ORIGINAL, before the file extension."
  (concat (file-name-sans-extension original) " " name "."
          (or extension (file-name-extension original))))

(defun my-adjust-subtitles (offset)
  "Change all of the start and end times by OFFSET."
  (interactive (list (subed--string-to-msecs (read-string "Time: "))))
  (subed-for-each-subtitle (point-min) (point-max) nil
                           (subed-adjust-subtitle-time-start offset t t)
                           (subed-adjust-subtitle-time-stop offset t t))
  (subed-regenerate-ids))

(defun my-subed-write-adjusted-subtitles (source-file start-msecs end-msecs dest-file)
  (let ((s (with-current-buffer (find-file-noselect source-file)
             (buffer-substring-no-properties
              (subed-jump-to-subtitle-id-at-msecs start-msecs)
              (progn (subed-jump-to-subtitle-id-at-msecs end-msecs) (subed-jump-to-subtitle-end)))))
        (offset (- start-msecs)))
    (with-current-buffer (find-file-noselect dest-file)
      (erase-buffer)
      (insert s)
      (my-adjust-subtitles offset)
      (save-buffer)
      (buffer-file-name))))

(defun my-msecs-to-timestamp (msecs)
  "Convert MSECS to string in the format HH:MM:SS.MS."
  (concat (format-seconds "%02h:%02m:%02s" (/ msecs 1000))
          "." (format "%03d" (mod msecs 1000))))

(defun my-subed-make-animated-gif (beg end name)
  (interactive "r\nMName: ")
  (let* ((video-file (subed-guess-video-file))
         (msecs (my-subed-get-region-start-stop beg end))
         (new-file (my-extend-file-name video-file name "gif"))
         cmd)
    (when (> (length name) 0)
      (setq cmd
            (format "ffmpeg -y -i %s -ss %s -t %s -vf subtitles=%s -r 10 -c:a copy -shortest -async 1 %s"
                    (shell-quote-argument video-file)
                    (my-msecs-to-timestamp (car msecs))
                    (my-msecs-to-timestamp (- (cdr msecs) (car msecs)))
                    (shell-quote-argument (my-subed-write-adjusted-subtitles beg end name))
                    (shell-quote-argument new-file)))
      (message "%s" cmd)
      (kill-new cmd)
      (shell-command cmd))))

(defun my-subed-ffmpeg-make-mute-filter (segments)
  (mapconcat
   (lambda (s)
     (format "volume=enable='between(t,%.3f,%.3f)':volume=0"
             (/ (car s) 1000.0)
             (/ (cdr s) 1000.0)))
   segments ", "))

(defun my-subed-cut-video (beg end name video-file caption-file &optional kill-only)
  (interactive
   (append
    (if (use-region-p)
        (list (point) (mark))
      (list (save-excursion (subed-jump-to-subtitle-id))
            (save-excursion (subed-jump-to-subtitle-end))))
    (list
     (expand-file-name (read-file-name "New video filename: "))
     (if (derived-mode-p 'subed-mode) (expand-file-name (subed-media-file))
       (read-file-name "Video: "))
     (if (derived-mode-p 'subed-mode) (expand-file-name (buffer-file-name))
       (read-file-name "Captions: ")))))
  (let*
      ((msecs (my-subed-get-region-start-stop beg end))
       (new-file name)
       cmd)
    (when (> (length name) 0)
      (setq cmd
            (format "ffmpeg -y -i %s -i %s -ss %s -t %s -shortest -async 1 %s"
                    (shell-quote-argument caption-file)
                    (shell-quote-argument video-file)
                    (my-msecs-to-timestamp
                     (car msecs))
                    (my-msecs-to-timestamp
                     (-
                      (cdr msecs)
                      (car msecs)))
                    (shell-quote-argument new-file)))
      (message "%s" cmd)
      (if kill-only (kill-new cmd)
        (shell-command cmd)))))

(define-minor-mode my-subed-hide-nontext-minor-mode
  "Minor mode for hiding non-text stuff.")
(defun my-subed-hide-nontext-overlay (start end)
  (let ((new-overlay (make-overlay start end)))
    (overlay-put new-overlay 'invisible t)
    (overlay-put new-overlay 'intangible t)
    (overlay-put new-overlay 'evaporate t)
    (overlay-put new-overlay 'read-only t)
    (overlay-put new-overlay 'hide-non-text t)
    (with-silent-modifications
      (add-text-properties start end '(read-only t)))
    new-overlay))

(defun my-subed-hide-nontext ()
  (interactive)
  (remove-overlays (point-min) (point-max) 'invisible t)
  (when my-subed-hide-nontext-minor-mode
    (save-excursion
      (goto-char (point-min))
      (subed-jump-to-subtitle-id)
      (my-subed-hide-nontext-overlay (point-min) (subed-jump-to-subtitle-text))
      (let (next)
        (while (setq next (save-excursion (subed-forward-subtitle-text)))
          (subed-jump-to-subtitle-end)
          (my-subed-hide-nontext-overlay (1+ (point)) (1- next))
          (subed-forward-subtitle-text))))))

(defun my-subed-show-all ()
  (interactive)
  (let ((inhibit-read-only t))
    (with-silent-modifications
      (remove-text-properties (point-min) (point-max) '(read-only t))
      (remove-overlays (point-min) (point-max) 'invisible t))))

(defun my-ignore-read-only (f &rest args)
  (let ((inhibit-read-only t))
    (apply f args)
    (my-subed-hide-nontext)))

(advice-add 'subed-split-and-merge-dwim :around #'my-ignore-read-only)
(advice-add 'subed-split-subtitle :around #'my-ignore-read-only)
(advice-add 'subed-merge-with-next :around #'my-ignore-read-only)
(advice-add 'subed-merge-with-previous :around #'my-ignore-read-only)
(advice-add 'subed-regenerate-ids :around #'my-ignore-read-only)
(advice-add 'subed-kill-subtitle :around #'my-ignore-read-only)

(defun my-subed-forward-word (&optional arg)
  "Skip timestamps."
  (interactive "^p")
  (setq arg (or arg 1))
  (let ((end (or (save-excursion (subed-jump-to-subtitle-end)) (point))))
    (loop while (> arg 0)
          do
          (forward-word 1)
          (skip-syntax-forward "^\s")
          (setq arg (1- arg))
          (when (> (point) end)
            (subed-jump-to-subtitle-text)
            (forward-word 1)
            (skip-syntax-forward "^\s")
            (setq end (or (save-excursion (subed-jump-to-subtitle-end)) (point)))))))

(defun my-subed-backward-word (&optional arg)
  "Skip timestamps."
  (interactive "^p")
  (setq arg (or arg 1))
  (let ((end (or (save-excursion (subed-jump-to-subtitle-text)) (point))))
    (loop while (> arg 0)
          do
          (backward-word 1)
          (setq arg (1- arg))
          (when (< (point) end)
            (subed-backward-subtitle-text)
            (setq end (point))
            (subed-jump-to-subtitle-end)
            (backward-word 1)))))

(defhydra my-subed ()
  "Make it easier to split and merge"
  ("e" subed-jump-to-subtitle-end "End")
  ("s" subed-jump-to-subtitle-text "Start")
  ("f" my-subed-forward-word "Forward word")
  ("b" my-subed-backward-word "Backward word")
  ("w" avy-goto-word-1-below "Jump to word")
  ("n" subed-forward-subtitle-text "Forward subtitle")
  ("p" subed-backward-subtitle-text "Backward subtitle")
  (".p" (subed-split-and-merge-dwim 'prev) "Split and merge with previous")
  (".n" (subed-split-and-merge-dwim 'next) "Split and merge with next")
  ("mp" subed-merge-with-previous "Merge previous")
  ("mn" subed-merge-with-next "Merge next")
  ("j" subed-mpv-jump-to-current-subtitle "MPV current")
  ("1" (subed-mpv-playback-speed 1.0) "1x speed")
  ("2" (subed-mpv-playback-speed 0.7) "0.7x speed")
  ("3" (subed-mpv-playback-speed 0.5) "0.5x speed")
  (" " subed-mpv-pause "Pause")
  ("[" (subed-mpv-seek -1000) "-1s")
  ("]" (subed-mpv-seek 1000) "-1s")
  (";" (re-search-forward "[,\\.;]") "Search for break")
  ("uu" (subed-split-and-merge-dwim 'prev) "Split and merge with previous")
  ("hh" (subed-split-and-merge-dwim 'next) "Split and merge with next")
  ("hu" subed-merge-with-previous "Merge with previous")
  ("uh" subed-merge-with-next "Merge with next")
  ("lf" subed-mpv-find-video "Find video file")
  ("lu" subed-mpv-play-url "Find video at URL")
  ("x" kill-word "Kill word")
  ("S" save-buffer "Save")
  ("o" (insert "\n") (let ((fill-column (point-max))) (fill-paragraph))))

(use-package! subed
  :config
  (setq subed-subtitle-spacing 1)
  (setq subed-align-mfa-conda-env "/home/sacha/vendor/miniconda3/envs/aligner")
  (key-chord-define subed-mode-map "hu" 'my-subed/body)
  (key-chord-define subed-mode-map "ht" 'my-subed/body)
  (setq subed-loop-seconds-before 0 subed-loop-seconds-after 0)
  (setq subed-align-mfa-command '("mfa" "align"))
  (setq subed-align-mfa-conda-env "/home/sacha/vendor/miniconda3/envs/aligner")
  (setq subed-align-command
        '("/home/sacha/vendor/aeneas/venv/bin/python3" "-m" "aeneas.tools.execute_task"))
  :bind
  (:map subed-mode-map
        ("M-j" . avy-goto-char-timer)
        ("M-j" . subed-mpv-jump-to-current-subtitle)
        ("M-!" . subed-mpv-seek)))

(use-package! subed-record
  :config
  (remove-hook 'subed-sanitize-functions 'subed-sort)
  (setq subed-record-ffmpeg-args (split-string "-y -f pulse -i VirtualMicSink.monitor -r 48000"))
  :bind
  (:map subed-mode-map ("C-c C-c" . subed-record-compile-video)))

(defvar my-subed-audio-link-list nil)

(defun my-subed-remove-audio-links (beg end)
  (interactive (if (region-active-p)
                   (list (region-beginning)
                         (region-end))
                 (save-excursion
                   (org-back-to-heading)
                   (org-end-of-meta-data t)
                   (list (point)
                         (save-excursion (org-end-of-subtree)
                                         (point))))))
  (save-excursion
    (goto-char beg)
    (while (re-search-forward "vtime:[0-9:]+ +" nil t)
      (replace-match ""))))

(defun my-subed-load-audio-links (&optional op)
  (interactive (list
                (cond
                 ((null current-prefix-arg) 'insert)
                 ((equal current-prefix-arg '(4)) 'list)
                 ((equal current-prefix-arg '(16)) 'skip))))
  (cond
   ((derived-mode-p 'subed-mode)
    (setq my-subed-audio-link-list (subed-subtitle-list)))
   ((derived-mode-p 'org-mode)
    (save-excursion
      (unless (eq 'link (org-element-type (org-element-context)))
        (re-search-backward "\\(audio\\|video\\):"))
      (let ((filename
             (car
              (url-path-and-query (url-generic-parse-url (org-element-property :path (org-element-context)))))))
        (setq my-subed-audio-link-list
              (seq-filter
               (lambda (o)
                 (and (elt o 3) (not (string= (elt o 3) ""))))
               (subed-parse-file
                (concat (file-name-sans-extension filename)
                        ".vtt"))))))
    (pcase op
      ('insert (call-interactively #'my-subed-insert-audio-links))
      ('list (my-subed-insert-audio-links-as-list)))
    my-subed-audio-link-list)))

(defun my-subed-remove-audio-links (beg end)
  "Remove audio links from region."
  (interactive (cond
                ((region-active-p)
                 (list (region-beginning)
                       (region-end)))
                ((org-in-block-p '("media-post"))
                 (let ((block (org-element-lineage (org-element-context) 'special-block)))
                   (list
                    (org-element-begin block)
                    (org-element-end block))))
                (t
                 (list
                  (point-min) (point-max)))))
  (save-excursion
    (goto-char beg)
    (while (re-search-forward "vtime:[0-9:]+ " end t)
      (replace-match ""))))

(defun my-org-next-item-or-paragraph (&optional by-sentence)
  (cond
   ((org-in-item-p)
    (condition-case nil
        (progn
          (org-next-item)
          (when (looking-at org-list-full-item-re)
            (goto-char (match-end 0))))
      (error nil)))
   (by-sentence (forward-sentence))
   (t
    (forward-paragraph)
    (skip-syntax-forward " ")
    (when (looking-at org-list-full-item-re)
      (goto-char (match-end 0)))
                                        ; Move to start of a list item
    (when (looking-at org-heading-regexp)
      (org-end-of-meta-data t))
    (skip-syntax-forward " "))))

(defun my-org-vtime-link (o &optional keep-hours)
  (concat "vtime:"
          (if (or keep-hours (>= (elt o 1) (* 60 60 1000)))
              (substring (car o) 0 8)
            (substring (car o) 3 8))))

(defun my-subed-insert-next-audio-link (&optional by-sentence)
  (interactive (list current-prefix-arg))
  (let* ((candidates
          (seq-keep (lambda (o)
                      (unless (string= (string-trim (elt o 3)) "")
                        (cons (replace-regexp-in-string "<.+?>" "" (elt o 3))
                              (car o))))
                    my-subed-audio-link-list))
         (sentence
          (my-org-simplify-text
           (replace-regexp-in-string
            "\\*" ""
            (replace-regexp-in-string
             " *{.+?}" ""
             (let ((sentence (sentence-at-point))
                   (subs (buffer-substring (point) (line-end-position))))
               (if (and sentence (< (length sentence) (length subs)))
                   sentence
                 subs))))))
         (choice
          (or
           (cdr
            (seq-find
             (lambda (o)
               (subed-word-data-compare-normalized-string-distance
                sentence
                (replace-regexp-in-string
                 "\\*" ""
                 (replace-regexp-in-string " *{.+?}" "" (car o)))))
             candidates))
           (consult--read
            candidates
            :lookup 'consult--lookup-cdr
            :sort nil))))
    (save-excursion
      (insert "vtime:" (replace-regexp-in-string "\\.[0-9]+" choice) " "))
    (my-org-next-item-or-paragraph by-sentence)
    (setq my-subed-audio-link-list
          (seq-remove
           (lambda (o) (string= (car o) choice))
           my-subed-audio-link-list))))

(defun my-subed-insert-audio-links (&optional beg end do-load)
  (interactive (cond
                ((region-active-p)
                 (list (region-beginning)
                       (region-end)
                       current-prefix-arg))
                ((org-in-block-p '("media-post"))
                 (let ((block (org-element-lineage (org-element-context) 'special-block)))
                   (list
                    (org-element-begin block)
                    (org-element-end block)
                    current-prefix-arg)))
                (t
                 (list
                  (point-min) (point-max)
                  current-prefix-arg))))
  (setq beg (or beg (point)))
  (setq end (or end (point-max)))
  (when do-load
    (save-excursion
      (unless (eq 'link (org-element-type (org-element-context)))
        (re-search-backward "audio:" nil t))
      (let ((elem (org-element-context)))
        (when (and (eq 'link (org-element-type elem))
                   (string= "audio" (org-element-property :type elem)))
          (my-subed-save-audio-links)
          (my-org-next-item-or-paragraph)))))
  (save-restriction
    (narrow-to-region beg end)
    (while (and my-subed-audio-link-list
                (not (eobp)))
      (my-subed-insert-next-audio-link))))

(defun my-subed-insert-audio-links-as-list ()
  (interactive)
  (dolist (cue my-subed-audio-link-list)
    (insert "- " (my-org-vtime-link cue) " " (elt cue 3) "\n")))

(defun my-subed-fix-timestamps ()
  "Change all ending timestamps to the start of the next subtitle."
  (interactive)
  (goto-char (point-max))
  (let ((timestamp (subed-subtitle-msecs-start)))
    (while (subed-backward-subtitle-time-start)
      (subed-set-subtitle-time-stop timestamp)
      (setq timestamp (subed-subtitle-msecs-start)))))

(defun my-caption-download-srv2 (id)
  (interactive "MID: ")
  (require 'subed-word-data)
  (when (string-match "v=\\([^&]+\\)" id) (setq id (match-string 1 id)))
  (let ((default-directory "/tmp"))
    (call-process "yt-dlp" nil nil nil "--write-auto-sub" "--write-sub" "--no-warnings" "--sub-lang" "en" "--skip-download" "--sub-format" "srv2"
                  (concat "https://youtu.be/" id))
    (subed-word-data-load-from-file (my-latest-file "/tmp" "\\.srv2\\'"))))

(defun my-caption-fix-common-errors (data)
  (mapc (lambda (o)
          (mapc (lambda (e)
                  (when (string-match (concat "\\<" (regexp-opt (if (listp e) (seq-remove (lambda (s) (string= "" s)) e)
                                                                  (list e)))
                                              "\\>")
                                      (alist-get 'text o))
                    (map-put! o 'text (replace-match (car (if (listp e) e (list e))) t t (alist-get 'text o)))))
                my-subed-common-edits))
        data))

(defun subed-avy-set-up-actions ()
  (interactive)
  (make-local-variable 'avy-dispatch-alist)
  (add-to-list
   'avy-dispatch-alist
   (cons ?, 'subed-split-subtitle)))

(defun my-subed-maybe-save-place ()
  (when buffer-file-name (save-place-local-mode 1)))

(use-package! subed
  ;; :mode
  ;; (("\\.vtt\\'" . subed-vtt-mode)
  ;;  ("\\.srt\\'" . subed-srt-mode)
  ;;  ("\\.ass\\'" . subed-ass-mode))
  ;; :init
  ;; (autoload 'subed-vtt-mode "subed-vtt" nil t)
  ;; (autoload 'subed-srt-mode "subed-srt" nil t)
  ;; (autoload 'subed-ass-mode "subed-ass" nil t)
  ;; (autoload 'subed-txt-mode "subed-txt" nil t)

  ;; ;; (require 'subed-autoloads)
  ;; :hook
  ;; (subed-mode . display-fill-column-indicator-mode)
  ;; (subed-mode . subed-avy-set-up-actions)
  :bind
  (:map subed-mode-map
        ("M-," . subed-split-subtitle)
        ("M-." . subed-merge-dwim))
  :config
  ;; Remember cursor position between sessions
  (add-hook 'subed-mode-hook 'save-place-local-mode)
  ;; Break lines automatically while typing
  (add-hook 'subed-mode-hook 'turn-on-auto-fill)
  ;; Break lines at 40 characters
  (add-hook 'subed-mode-hook (lambda () (setq-local fill-column 40)))
  ;; Some reasonable defaults
  (add-hook 'subed-mode-hook 'subed-enable-pause-while-typing)
  ;; As the player moves, update the point to show the current subtitle
  (add-hook 'subed-mode-hook 'subed-enable-sync-point-to-player)
  ;; As your point moves in Emacs, update the player to start at the current subtitle
  (add-hook 'subed-mode-hook 'subed-enable-sync-player-to-point)
  ;; Replay subtitles as you adjust their start or stop time with M-[, M-], M-{, or M-}
  (add-hook 'subed-mode-hook 'subed-enable-replay-adjusted-subtitle)
  ;; Loop over subtitles
  (add-hook 'subed-mode-hook 'subed-enable-loop-over-current-subtitle)
  ;; Show characters per second
  (add-hook 'subed-mode-hook 'subed-enable-show-cps)
  (with-eval-after-load 'consult
    (advice-add 'consult-buffer :around
                (lambda (f &rest r)
                  (let ((subed-auto-play-media nil))
                    (apply f r)))))

  )


(defvar my-caption-breaks
  '("the" "this" "we" "we're" "I" "finally" "but" "and" "when")
  "List of words to try to break at.")

(defun my-caption-make-groups (list &optional threshold)
  (let (result
        current-item
        done
        (current-length 0)
        (limit (or threshold 70))
        (lower-limit 30)
        (break-regexp (concat "\\<" (regexp-opt my-caption-breaks) "\\>")))
    (while list
      (cond
       ((null (car list)))
       ((string-match "^\n*$" (alist-get 'text (car list)))
        (push (cons '(text . " ") (car list)) current-item)
        (setq current-length (1+ current-length)))
       ((< (+ current-length (length (alist-get 'text (car list)))) limit)
        (setq current-item (cons (car list) current-item)
              current-length (+ current-length (length (alist-get 'text (car list))) 1)))
       (t (setq done nil)
          (while (not done)
            (cond
             ((< current-length lower-limit)
              (setq done t))
             ((and (string-match break-regexp (alist-get 'text (car current-item)))
                   (not (string-match break-regexp (alist-get 'text (cadr current-item)))))
              (setq current-length (- current-length (length (alist-get 'text (car current-item)))))
              (push (pop current-item) list)
              (setq done t))
             (t
              (setq current-length (- current-length (length (alist-get 'text (car current-item)))))
              (push (pop current-item) list))))
          (push nil list)
          (setq result (cons (reverse current-item) result) current-item nil current-length 0)))
      (setq list (cdr list)))
    (reverse result)))

(defun my-caption-format-as-subtitle (list &optional word-timing)
  "Turn a LIST of the form (((start . ms) (end . ms) (text . s)) ...) into VTT.
If WORD-TIMING is non-nil, include word-level timestamps."
  (format "%s --> %s\n%s\n\n"
          (subed-vtt--msecs-to-timestamp (alist-get 'start (car list)))
          (subed-vtt--msecs-to-timestamp (alist-get 'end (car (last list))))
          (s-trim (mapconcat (lambda (entry)
                               (if word-timing
                                   (format " <%s>%s"
                                           (subed-vtt--msecs-to-timestamp (alist-get 'start entry))
                                           (string-trim (alist-get 'text entry)))
                                 (alist-get 'text entry)))
                             list ""))))

(defun my-caption-to-vtt (&optional data)
  (interactive)
  (with-temp-file "captions.vtt"
    (insert "WEBVTT\n\n"
            (mapconcat
             (lambda (entry) (my-caption-format-as-subtitle entry))
             (my-caption-make-groups
              (or data (my-caption-fix-common-errors subed-word-data--cache)))
             ""))))


(defun my-subed-word-tsv-from-whisperx-json (file)
  (interactive "FJSON: ")
  (let* ((json-array-type 'list)
         (json-object-type 'alist)
         (data (json-read-file file))
         (filename (concat (file-name-sans-extension file) ".tsv"))
         (base (seq-mapcat
                (lambda (segment)
                  (seq-map (lambda (word)
                             (let-alist word
                               (list nil
                                     (and .start (* 1000 .start))
                                     (and .end (* 1000 .end))
                                     .word)))
                           (alist-get 'words segment)))
                (alist-get 'segments data)))
         (current base)
         (last-end 0))
    ;; numbers at the end of a sentence sometimes don't end up with times
    ;; so we need to fix them
    (while current
      (unless (elt (car current) 1)           ; start
        (setf (elt (car current) 1) (1+ last-end)))
      (unless (elt (car current) 2)
        (setf (elt (car current) 2) (1- (elt (cadr current) 1))))
      (setq
       last-end (elt (car current) 2)
       current (cdr current)))
    (subed-create-file
     filename
     base
     t
     'subed-tsv-mode)
    (find-file filename)))

(defun my-subed-load-word-data-from-whisperx-highlights (file)
  "Return a list of word cues from FILE.
FILE should be a VTT or SRT file produced by whisperx with the
--highlight_words True option."
  (seq-keep (lambda (sub)
              (when (string-match "<u>\\(.+?\\)</u>" (elt sub 3))
                (setf (elt sub 3) (match-string 1 (elt sub 3)))
                sub))
            (subed-parse-file file)))

(defun my-subed-word-tsv-from-whisperx-highlights (file)
  (interactive "FVTT: ")
  (with-current-buffer (find-file-noselect (concat (file-name-nondirectory file) ".tsv"))
    (erase-buffer)
    (subed-tsv-mode)
    (subed-auto-insert)
    (mapc (lambda (sub) (apply #'subed-append-subtitle nil (cdr sub)))
          (my-subed-load-word-data-from-whisperx-highlights file))
    (switch-to-buffer (current-buffer))))

(defvar my-subed-merge-close-subtitles-threshold 500)
(defun my-subed-merge-close-subtitles (threshold)
  "Merge subtitles with the following one if there is less than THRESHOLD msecs gap between them."
  (interactive (list (read-number "Threshold in msecs: " my-subed-merge-close-subtitles-threshold)))
  (goto-char (point-min))
  (while (not (eobp))
    (let ((end (subed-subtitle-msecs-stop))
          (next-start (save-excursion
                        (and (subed-forward-subtitle-time-start)
                             (subed-subtitle-msecs-stop)))))
      (if (and end next-start (< (- next-start end) threshold))
          (subed-merge-with-next)
        (or (subed-forward-subtitle-end) (goto-char (point-max)))))))

(defvar my-subed-skim-msecs 1000 "Number of milliseconds to play when skimming.")
(defun my-subed-skim-starts ()
  (interactive)
  (subed-mpv-unpause)
  (subed-disable-loop-over-current-subtitle)
  (catch 'done
    (while (not (eobp))
      (subed-mpv-jump-to-current-subtitle)
      (let ((ch
             (read-char "(q)uit? " nil (/ my-subed-skim-msecs 1000.0))))
        (when ch
          (throw 'done t)))
      (subed-forward-subtitle-text)
      (when (and subed-waveform-minor-mode
                 (not subed-waveform-show-all))
        (subed-waveform-refresh))
      (recenter)))
  (subed-mpv-pause))

(defvar my-filler-words-regexp "\\(\\. \\|^\\)\\(?:So?\\|And\\|You know\\|Uh\\)\\(?:,\\|\\.\\.\\.\\)? \\(.\\)")
(defun my-remove-filler-words-at-start ()
  (interactive)
  (save-excursion
    (let ((case-fold-search nil))
      (while (re-search-forward my-filler-words-regexp nil t)
        (if (and (called-interactively-p) (not current-prefix-arg))
            (let ((overlay (make-overlay (match-beginning 0)
                                         (match-end 0))))
              (overlay-put overlay 'common-edit t)
              (overlay-put overlay 'evaporate t)
              (overlay-put
               overlay 'display
               (propertize (concat (match-string 0) " -> "
                                   (match-string 1)
                                   (upcase (match-string 2)))
                           'face 'modus-themes-mark-sel))
              (unwind-protect
                  (pcase (save-match-data (read-char-choice "Replace (y/n/!/q)? " "yn!q"))
                    (?!
                     (replace-match (concat (match-string 1) (upcase (match-string 2))) t)
                     (while (re-search-forward my-filler-words-regexp nil t)
                       (replace-match (concat (match-string 1) (upcase (match-string 2))) t)))
                    (?y
                     (replace-match (concat (match-string 1) (upcase (match-string 2))) t))
                    (?n nil)
                    (?q (goto-char (point-max))))
                (delete-overlay overlay)))
          (replace-match (concat (match-string 1) (upcase (match-string 2))) t))))))

(defun my-caption-show (url)
  (interactive (list
                (let ((link (and (derived-mode-p 'org-mode)
                                 (org-element-context))))
                  (if (and link
                           (eq (org-element-type link) 'link))
                      (read-string (format "URL (%s): " (org-element-property :raw-link link)) nil nil
                                   (org-element-property :raw-link link))
                    (read-string "URL: ")))))
  (when (and (listp url) (org-element-property :raw-link url)) (setq url (org-element-property :raw-link url)))
  (delete-other-windows)
  (split-window-right)
  (if (string-match "http" url)
      (with-current-buffer-window "*Captions*"
          'display-buffer-same-window
          nil
        (org-mode)
        (save-excursion
          (my-org-insert-youtube-video-with-transcript url)))
    (unless (file-exists-p (concat (file-name-sans-extension url) ".vtt"))
      (my-deepgram-recognize-audio url))
    (find-file (concat (file-name-sans-extension url) ".vtt"))))

;; Use the saved version of this instead of forcing the reevaluation
(defcustom my-subed-common-edits
  '("I"
    "I've"
    "I'm"
    "Mendeley"
    "JavaScript"
    "RSS"
    ("stop section" "subsection")
    ("EmacsConf" "EmacsCon" "emacs conf" "imaxconf")
    ("going to" "gonna")
    ("want to" "wanna")
    ("transient" "transit")
    ("C-c" "control c" "Ctrl+C")
    ("C-x" "control x" "Ctrl+X")
    ("C-f" "control f")
    ("" "uh" "um")
    ("Magit" "maggot")
    ("Emacs" "e-max" "emex" "emax" "bmx" "imax")
    ("Emacs News" "emacs news")
    ("Emacs Lisp" "emacs list")
    ("ivy" "iv")
    ("UI" "ui")
    ("TECO" "tico")
    ("org-roam" "orgrim" "orgrom" "Org Rome")
    ("non-nil" "non-nail")
    ("commits" "comets")
    "SQL"
    "arXiv"
    "Montessori"
    "SVG"
    "YouTube" "GitHub" "GitLab" "OmegaT" "Linux" "SourceForge"
    "LaTeX"
    "Lisp"
    "Org"
    "IRC"
    "Reddit"
    "PowerPoint"
    "SQLite"
    "SQL"
    "I'll"
    ("<f9>" "F-9" "f9")
    "I'd"
    "PDFs"
    "PDF"
    "ASCII"
    ("Spacemacs" "spacemax")
    "Elisp"
    "Reddit"
    "TextMate"
    "macOS"
    "API"
    "IntelliSense"
    ("EXWM" "axwm")
    ("Emacs's" "emax's")
    ("BIDI" "bd")
    ("Perso-Arabic" "personal arabic")
    "Persian"
    "URL"
    "HTML"
    ("vdo.ninja" "Video Ninja"))
  "Commonly-misrecognized words or words that need special capitalization."
  :group 'sachac
  :type '(repeat (choice string
                         (repeat string))))


(defun my-subed-add-common-edit (beg end replacement)
  "Add this word to the misrecognized words."
  (interactive
   (let ((beg (if (region-active-p) (min (point) (mark))
                (skip-syntax-backward "w")
                (point)))
         (end (if (region-active-p) (max (point) (mark))
                (save-excursion (forward-word 1) (point)))))
     (list beg end
           (completing-read
            (format "Replacement (%s): " (buffer-substring beg end))
            (mapcar (lambda (o) (if (stringp o) o (car o))) my-subed-common-edits)))))
  (customize-set-variable
   'my-subed-common-edits
   (cond
    ((member replacement my-subed-common-edits)
     (cons (list replacement (buffer-substring-no-properties beg end))
           (delete replacement my-subed-common-edits)))
    ((assoc replacement my-subed-common-edits)
     (setcdr (assoc replacement my-subed-common-edits)
             (append (list replacement) (cdr (assoc replacement my-subed-common-edits))))
     my-subed-common-edits)
    (t
     (push (list replacement (buffer-substring-no-properties beg end))
           my-subed-common-edits))))
  (delete-region beg end)
  (insert replacement))

(defun my-subed-find-next-fix-point ()
  (when (re-search-forward
         (format "\\<%s\\>"
                 (downcase
                  (regexp-opt (seq-mapcat
                               (lambda (o)
                                 (if (listp o)
                                     (if (string= (car o) "") (cdr o) o)
                                   (list o)))
                               my-subed-common-edits))))
         nil t)
    (goto-char (match-beginning 0))
    (seq-find (lambda (o)
                (if (listp o)
                    (seq-find (lambda (s) (string= (downcase s) (downcase (match-string 0)))) o)
                  (string= (downcase o) (downcase (match-string 0)))))
              my-subed-common-edits)))

(defun my-subed-fix-common-error ()
  (interactive)
  (let ((entry (my-subed-find-next-fix-point)))
    (replace-match (if (listp entry) (car entry) entry) t t)))

(defun my-subed-fix-common-errors ()
  (interactive)
  (let (done entry correction)
    (while (and
            (not done)
            (setq entry (my-subed-find-next-fix-point)))
      (setq correction (if (listp entry) (car entry) entry))
      (if (called-interactively-p 'any)
          (let* ((c (read-char (format "%s (yn.): " correction))))
            (cond
             ((= c ?y) (replace-match correction t t))
             ((= c ?n) (goto-char (match-end 0)))
             ((= c ?j) (subed-mpv-jump-to-current-subtitle))
             ((= c ?.) (setq done t))))
        (replace-match correction t t)))))

(defun my-subed-fix-common-errors-from-start ()
  (goto-char (point-min))
  (my-subed-fix-common-errors))


(provide 'setup-multimedia)
;;; setup-multimedia.el ends here
