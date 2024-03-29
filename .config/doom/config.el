;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;;(setq user-full-name "John Doe"
;;      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
(setq doom-font (font-spec :family "monospace" :size 25 :height 1.25)
      doom-variable-pitch-font (font-spec :family "sans-serif" :size 25 :height 1.25))
(set-face-attribute 'italic nil    ;affects M-x function descriptions & org-mode
                    :slant 'italic
                    :underline nil
                    :family "JetBrains Mono")
(custom-set-faces!                      ;affects comments in source codes
  '(font-lock-comment-face :slant italic :underline nil :family "JetBrains Mono"))

;; It seems like emacs don't respect fontconfig,
;; so I have to manualy set the font for CJK characters
(defun init-cjk-fonts ()
  (dolist (script '(han kana hangul cjk-misc bopomofo))
    (set-fontset-font t script "Noto Sans Mono CJK SC")))
(add-hook 'after-setting-font-hook #'init-cjk-fonts)

;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;;(setq doom-theme 'doom-one)
(defun hash-table-keys-to-string (procedure hash-table separator)
  (mapconcat procedure
             (hash-table-keys hash-table) ;faster than using `concat` in a loop
             separator))

(defun object-to-string (object)
  (format "%s" object))

(defun string-translate (str table)
  (replace-regexp-in-string
   (hash-table-keys-to-string (lambda (x) (regexp-quote (object-to-string x)))
                              table
                              "\\|")
   (lambda (match) (gethash match table))
   str))

(defun safe-subseq (list start end)
  (seq-take (seq-drop list start) (- end start)))

(require 's)

(cl-defun run-process (command &key filter sentinel name)
  "Return the exit code and output of a given process."
  (with-temp-buffer
    (let* ((name (if (null name)
                     (mapconcat #'s-trim-right
                                (safe-subseq command 0 2)
                                " ")
                   name))
           (filter (if (null filter)
                       (lambda (process output)
                         (insert output))
                     filter))
           (sentinel (if (null sentinel)
                         #'ignore
                       sentinel))
           (process (funcall #'make-process
                             :name name
                             :buffer (current-buffer)
                             :command command
                             :noquery t
                             :filter filter
                             :sentinel sentinel)))
      (while (process-live-p process)
        (accept-process-output process))
      (cons (process-exit-status process) (buffer-string)))))
(defun status-process (process)
  (car process))
(defun output-process (process)
  (cdr process))

(cl-defun run-process-with-message (command &key filter sentinel name)
  (apply #'run-process
         command
         :filter (if (null filter)
                     (lambda (process output)
                       (message "%s"
                                (string-translate
                                 (s-trim-right output)
                                 #s(hash-table
                                    size 2
                                    test equal
                                    data ("\r" "\n"
                                          "\^[[K" "")))))
                   filter)
         (append (if (null sentinel)
                     '()
                   (list ':sentinel sentinel))
                 (if (null name)
                     '()
                   (list ':name name)))))

(defun extend (&rest lists)
  (let ((lst (car lists))
        (tail (cdr lists)))
    (apply #'nconc lst tail)
    lst))

(defun safe-trash (file)
  (when (file-exists-p file)
    (move-file-to-trash file)))

(defun valid-repo? (directory)
  (and (file-directory-p (expand-file-name ".git" directory))
       (= 0 (let ((default-directory directory))
              (call-process "/usr/bin/git" nil nil nil "status")))))

(setq custom-theme-load-path
      (cl-remove-if (lambda (s)
                      (and (stringp s) (s-suffix? "doom-themes/" s)))
                    custom-theme-load-path))
(remove-hook 'after-init-hook #'doom-init-theme-h)

(let ((path (expand-file-name "~/.config/doom/everforest-theme/"))
      (repo-url "https://www.github.com/gaesa/emacs-everforest-theme")
      (branch "fork"))
  (if (valid-repo? path)
      (add-to-list 'custom-theme-load-path path)
    (safe-trash path)
    (message "%s" "Running (git clone) to fetch the custom theme")
    (run-process-with-message (extend '("/usr/bin/git" "clone")
                                      (list "--branch" branch) ;there is no `lexical-boundp'
                                      (list repo-url path)))
    (add-to-list 'custom-theme-load-path path)))

(cl-defun make-set (&optional lst &key (test 'equal))
  (let ((set (make-hash-table :test test)))
    (mapc (lambda (ele) (adjoin-set ele set)) lst)
    set))
(defun adjoin-set (element set)
  (puthash element t set))
(defun element-of-set? (element set)
  (gethash element set))
(defun remove-from-set (element set)
  (remhash element set))
(defun complement-set (set1 set2)
  (let ((result (make-set)))
    (maphash (lambda (key value)
               (if (not (element-of-set? key set2))
                   (adjoin-set key result)))
             set1)
    result))
(defun set->list (set)
  (let ((result-list '()))
    (maphash (lambda (key value)
               (push key result-list))
             set)
    result-list))
(defun pop! (lst1 lst2)
  (set->list (complement-set (make-set lst1)
                             (make-set lst2))))

(defun switch-theme (color)
  (let ((colors (make-set '(light dark) :test 'eq)))
    (if (element-of-set? color colors)
        (let ((desired-theme (intern (format "everforest-hard-%s" (symbol-name color))))
              (current-theme (if (null custom-enabled-themes)
                                 '()
                               (car custom-enabled-themes))))
          (if (not (eq current-theme desired-theme))
              (load-theme desired-theme t)
            '()))
      (error "Invalid color: %s" (symbol-name color)))))

(defun get-local-time ()
  (let ((current-time-structure (decode-time (current-time))))
    (list (nth 2 current-time-structure) (nth 1 current-time-structure))))

(defun between-times (date time-range)
  (let ((time-range-structure (mapcar (lambda (time)
                                        (mapcar #'string-to-number
                                                (split-string time ":")))
                                      time-range)))
    (cl-multiple-value-bind (start end) time-range-structure
      (and (not (time-less-p date start))
           (time-less-p date end)))))

(defun light-theme-time? (time-range)
  (between-times (get-local-time) time-range))

(defun switch-theme-if-needed (&optional time-range)
  (defun switch (time-range)
    (let ((desired-theme (if (light-theme-time? time-range)
                             'light
                           'dark)))
      (switch-theme desired-theme)))
  (if (null time-range)
      (switch '("06:00" "18:00"))
    (switch time-range)))

(defun for-each (procedure sequence)    ;support an optional index parameter
  (let* ((len-args (cdr (func-arity procedure)))
         (procedure (if (< len-args 2)
                        (lambda (element index)
                          (funcall procedure element))
                      procedure)))
    (defun iter-list (value n lst)
      (if (null lst)
          value
        (iter-list (funcall procedure (car lst) n)
                   (1+ n)
                   (cdr lst))))
    (defun iter-vector (value n len)
      (if (= n len)
          value
        (iter-vector (funcall procedure (aref sequence n) n)
                     (1+ n)
                     len)))
    (if (listp sequence)
        (iter-list '() 0 sequence)
      (iter-vector [] 0 (length sequence)))))

(let ((interval (* 24 60 60))
      (times '("06:00" "18:00"))
      (theme-table [light dark]))
  (add-hook 'after-init-hook (lambda () (switch-theme-if-needed times)))
  (for-each (lambda (time index)
              (run-at-time time interval
                           (lambda () (switch-theme (aref theme-table index)))))
            times))

;; Line number
(setq display-line-numbers-type 'relative)
(add-hook 'evil-insert-state-entry-hook
          (lambda () (setq display-line-numbers t)))
(add-hook 'evil-insert-state-exit-hook
          (lambda () (setq display-line-numbers 'relative))) ; or 'visual

;; Cursor
(setq evil-operator-state-cursor 'hbar)
;;(setq evil-motion-state-cursor 'box)  ; █
;;(setq evil-visual-state-cursor 'box)  ; █
;;(setq evil-normal-state-cursor 'box)  ; █
;;(setq evil-insert-state-cursor 'bar)  ; ⎸
;;(setq evil-emacs-state-cursor  'hbar) ; _
;;(setq etcc-term-type-override 'xterm)

;; Prevent the system clipboard from being used as the default option
(remove-hook 'tty-setup-hook #'doom-init-clipboard-in-tty-emacs-h)
(setq select-enable-clipboard nil
      kill-ring-max 50
      evil-visual-update-x-selection-p t)

(defun remove-current-kill ()
  "When interact with clipboard, `current-kill' uses `kill-new' to alter the `kill-ring',
`remove-current-kill' can fix that."
  (pop kill-ring)
  (if kill-ring-yank-pointer
      (setq kill-ring-yank-pointer kill-ring)))

(defun copy-string-to-clipboard (str)
  (let ((select-enable-clipboard t))
    (gui-select-text str)))

(defun get-string-from-clipboard ()
  (gui--selection-value-internal 'CLIPBOARD))

(defun get-current-kill ()
  (if (null kill-ring)
      nil
    (substring-no-properties (car kill-ring))))

(defun send-current-kill-to-clipboard ()
  (copy-string-to-clipboard
   (get-current-kill)))

(defun paste-from-clipboard-insert ()
  "Like `clipboard-yank', but doesn't alter `kill-ring'."
  (interactive "*")
  (insert (get-string-from-clipboard)))

;; HACK
;; See also: https://www.reddit.com/r/emacs/comments/9jbgbz/evil_mode_copy_and_paste_question/
;; Reason: Evil register ?+ cannot capture non-evil operations like `kill-region',
;; and it's hard to make it work under both normal mode and visual mode.
(defvar clipboard-enabled nil
  "Used to track the state of clilpboard.")

(defun closure-p (var)
  (and (consp var)
       (eq (car var) 'closure)))

(defun my/evil-clipboard (orig-fun &rest args)
  (defun reset (old-kill)
    (setq clipboard-enabled nil)
    (if (and (not (closure-p orig-fun))     ;`lispy-kill-at-point-fix'
             ;; follows the behavior of vim, isolating `kill-ring' from clipboard only when pasting
             (memq (intern (subr-name orig-fun))
                   #'(evil-paste-after
                      evil-paste-before
                      evil-paste-before-cursor-after))
             ;; `evil-paste-after' & `evil-paste-before' would not alter `kill-ring' in this case
             (not (string= old-kill (get-current-kill))))
        (remove-current-kill)))

  (if clipboard-enabled
      (let ((select-enable-clipboard t)
            (old-kill (get-current-kill)))
        (apply orig-fun args)
        (reset old-kill))
    (apply orig-fun args)))

(defvar clipboard-command-list
  '(evil-paste-after
    evil-paste-before
    evil-paste-before-cursor-after

    evil-yank
    evil-yank-line
    lispyville-yank
    lispyville-yank-line
    lispy-kill-at-point-fix             ;closure

    evil-delete
    evil-delete-line
    lispyville-delete
    lispyville-delete-line

    evil-delete-char
    evil-delete-backward-char
    lispyville-delete-char-or-splice
    lispyville-delete-char-or-splice-backwards

    evil-change
    evil-change-line
    lispyville-change
    lispyville-change-line

    evil-collection-magit-yank-whole-line
    magit-copy-buffer-revision
    magit-copy-section-value))

(mapc (lambda (fn) (advice-add fn :around #'my/evil-clipboard))
      clipboard-command-list)

(map! :leader "y" (lambda () (interactive)
                    (setq clipboard-enabled t)))

(defvar last-position (point)
  "Holds the cursor position from the last run of post-command-hooks.")
(defvar cursor-move-hook nil)

(defun my/cursor-move-callback ()
  (if (not (= (point) last-position))
      (progn (setq last-position (point))
             (run-hooks 'cursor-move-hook))))

(add-hook 'post-command-hook #'my/cursor-move-callback)

(add-hook 'cursor-move-hook (lambda ()
                              (if clipboard-enabled
                                  (setq clipboard-enabled nil))))

;; Remap
(define-key evil-insert-state-map (kbd "C-S-v") #'paste-from-clipboard-insert)
(define-key evil-insert-state-map (kbd "M-w") #'yank)
(define-key minibuffer-mode-map (kbd "C-S-v") #'paste-from-clipboard-insert)
(define-key minibuffer-mode-map (kbd "M-w") #'yank)
(define-key evil-normal-state-map (kbd "j") #'evil-next-visual-line)
(define-key evil-normal-state-map (kbd "k") #'evil-previous-visual-line)
(define-key evil-visual-state-map (kbd "j") #'evil-next-visual-line)
(define-key evil-visual-state-map (kbd "k") #'evil-previous-visual-line)
(define-key evil-normal-state-map (kbd "gj") #'evil-next-line)
(define-key evil-normal-state-map (kbd "gk") #'evil-previous-line)
(define-key evil-visual-state-map (kbd "gj") #'evil-next-line)
(define-key evil-visual-state-map (kbd "gk") #'evil-previous-line)
(define-key evil-normal-state-map (kbd "gx") #'browse-url-at-point)
(define-key evil-normal-state-map (kbd "q") #'evil-quit)
(define-key evil-normal-state-map (kbd "Q") #'evil-record-macro)
(define-key evil-normal-state-map (kbd "C-s") #'evil-save-modified-and-close)
(define-key evil-normal-state-map (kbd "C-q") (lambda () (interactive) (evil-quit-all t)))
(define-key evil-insert-state-map (kbd "M-h") #'evil-backward-char)
(define-key evil-insert-state-map (kbd "M-j") #'evil-next-visual-line)
(define-key evil-insert-state-map (kbd "M-k") #'evil-previous-visual-line)
(define-key evil-insert-state-map (kbd "M-l") #'evil-forward-char)
(define-key evil-insert-state-map (kbd "M-o") #'evil-open-below)
(define-key evil-insert-state-map (kbd "M-O") #'evil-open-above)
(define-key evil-insert-state-map (kbd "C-k") #'kill-line)
(define-key evil-motion-state-map (kbd "M-d") #'evil-jump-item)
(define-key evil-normal-state-map (kbd "M-d") #'evil-jump-item)
(define-key evil-visual-state-map (kbd "M-d") #'evil-jump-item)
(define-key evil-normal-state-map (kbd "C-n") nil)
(define-key evil-normal-state-map (kbd "C-p") nil)
(define-key evil-insert-state-map (kbd "C-n") nil)
(define-key evil-insert-state-map (kbd "C-p") nil)
(setq affe-find-command (remove ?\' (getenv "FZF_DEFAULT_COMMAND")))
(define-key doom-leader-map (kbd "f F") #'affe-find)

(defun my/center-line (&rest _)
  (evil-scroll-line-to-center nil))
(let ((functions '(evil-search-next             ;; n -> nzz
                   evil-ex-search-next          ;; n -> nzz
                   evil-search-previous         ;; N -> Nzz
                   evil-ex-search-previous      ;; N -> Nzz
                   evil-next-visual-line        ;; gj -> gjzz
                   evil-previous-visual-line    ;; gk -> gkzz
                   evil-scroll-up               ;; C-u -> C-u zz
                   evil-scroll-down             ;; C-d -> C-d zz
                   better-jumper-jump-forward   ;; C-i -> C-i zz
                   better-jumper-jump-backward  ;; C-o -> C-o zz
                   evil-ex-search-word-forward  ;; * -> *zz
                   evil-ex-search-word-backward ;; # -> #zz
                   evil-goto-line               ;; G -> Gzz
                   evil-jump-item               ;; % -> %zz
                   +lookup/definition           ;; gd -> gdzz
                   +lookup/references)))        ;; gD -> gDzz
  (mapc (lambda (fn) (advice-add fn :after #'my/center-line)) functions))

;; Line wrap
(+global-word-wrap-mode t)

;; Disable silly exit prompt
(setq confirm-kill-emacs nil)

;; Window
(add-to-list 'default-frame-alist '(fullscreen . maximized))
(setq mouse-autoselect-window t)        ;focus follow mouse

;; Dashboard
(setq doom-fallback-buffer-name "*dashboard*")
(use-package! dashboard
  :init
  (setq dashboard-display-icons-p t
        dashboard-icon-type 'nerd-icons
        dashboard-set-heading-icons t
        dashboard-set-file-icons t
        dashboard-center-content t
        dashboard-path-style 'truncate-middle
        dashboard-startup-banner (let ((file (expand-file-name "~/.local/share/icons-user/centaur.png")))
                                   (if (file-exists-p file)
                                       file
                                     'official))
        dashboard-set-footer nil
        dashboard-items '((recents . 5)
                          (agenda . 5))
        initial-buffer-choice (lambda () (get-buffer-create "*dashboard*")))
  :config
  (dashboard-setup-startup-hook)
  (evil-define-key 'normal dashboard-mode-map
    (kbd "q") #'evil-quit))

(let ((exclude-emacs-internal (lambda (filename)
                                (s-starts-with? (expand-file-name "~/.config/emacs")
                                                filename))))
  (pushnew! recentf-exclude exclude-emacs-internal))
(setq recentf-max-saved-items 20)

(advice-add '+workspace/kill-session :after
            (lambda (_) (let ((dashboard "*dashboard*"))
                          (when (not (null (get-buffer dashboard)))
                            (with-current-buffer dashboard
                              (setq default-directory "~/"))))))

;; Input method
(use-package! fcitx
  :after evil
  :config
  (when (setq fcitx-remote-command
              (or (executable-find "fcitx5-remote")
                  (executable-find "fcitx-remote")))
    (fcitx-evil-turn-on)))

(use-package! pangu-spacing
  :hook (text-mode . pangu-spacing-mode)
  :config
  ;; Always insert `real' space in org-mode.
  (setq-hook! 'org-mode-hook pangu-spacing-real-insert-separtor t))

;; Spell
;; default path doesn't respect XDG
(defvar spell-dict-location (expand-file-name "~/.config/dict/en"))
(setq ispell-check-comments nil
      spell-fu-idle-delay 0
      spell-fu-faces-exclude '(font-lock-comment-face)
      ispell-personal-dictionary spell-dict-location
      ispell-program-name "/usr/bin/hunspell")

(add-hook 'spell-fu-mode-hook
          (lambda ()
            (setq-local spell-fu-dictionaries nil) ;clear the default
            (spell-fu-dictionary-add (spell-fu-get-ispell-dictionary "en"))
            (spell-fu-dictionary-add
             (spell-fu-get-personal-dictionary "en-personal" spell-dict-location))))

(defvar spell-mode-alist '((git-commit-mode . (git-commit-comment-file
                                               git-commit-comment-action
                                               git-commit-comment-heading
                                               git-commit-comment-detached
                                               git-commit-comment-branch
                                               git-commit-comment-branch-local
                                               git-commit-comment-branch-remote))
                           (org-mode . (org-block
                                        org-block-begin-line
                                        org-block-end-line
                                        org-code
                                        org-date
                                        org-drawer org-document-info-keyword
                                        org-ellipsis
                                        org-link
                                        org-meta-line
                                        org-properties
                                        org-properties-value
                                        org-special-keyword
                                        org-src
                                        org-tag
                                        org-verbatim))))
(defun mode-to-hook (mode)
  (intern (concat (symbol-name mode) "-hook")))
(dolist (mode-to-faces spell-mode-alist)
  (let ((mode (car mode-to-faces)))
    (add-hook (mode-to-hook mode)
              (lambda ()
                (setq-local spell-fu-faces-exclude
                            (append spell-fu-faces-exclude
                                    (alist-get mode spell-mode-alist)))
                (spell-fu-mode)))))

;; refresh the word list at run-time when ispell updates the personal dictionary
;; see: https://github.com/emacsmirror/spell-fu#todo
(defun re-enable-spell (&optional _)
  (if spell-fu-mode
      (progn (spell-fu-mode -1)
             (spell-fu-mode 1))))
(mapc (lambda (orig-fn) (advice-add orig-fn :after #'re-enable-spell))
      '(spell-fu-word-add spell-fu-word-remove))

;; disable spell check in insert mode
(defun alistp (lst)
  (listp (car lst)))
(defun any-mode-active? (mode-list)
  (defun get-mode-choose (lst)
    (cond ((alistp lst)
           (lambda (mod-lst) (car (car mod-lst))))
          ((listp lst)
           (lambda (mod-lst) (car mod-lst)))
          (t
           (error "Not a symbol list or a symbol alist"))))
  ;; the function in elisp is not a first-class citizen object
  (fset 'get-mode (get-mode-choose mode-list))
  (defun iter (mode-list)
    (cond ((null mode-list) nil)
          ((let ((mode (get-mode mode-list)))
             (and (boundp mode) (symbol-value mode))) ;`bound-and-true-p' donot accept symbols
           t)
          (t (iter (cdr mode-list)))))
  (iter mode-list))

(defvar org-mode nil
  "fix org-mode check")
(make-variable-buffer-local 'org-mode)
(add-hook 'org-mode-hook (lambda () (setq-local org-mode t)))

(add-hook 'evil-insert-state-entry-hook
          (lambda () (if (any-mode-active? spell-mode-alist)
                         (spell-fu-mode -1))))
(add-hook 'evil-insert-state-exit-hook
          (lambda () (if (any-mode-active? spell-mode-alist)
                         (spell-fu-mode 1))))

;; keybindings on spell
(defalias '+spell/add-word #'spell-fu-word-add)
(defalias '+spell/remove-word #'spell-fu-word-remove)
(defalias '+spell/next-error #'spell-fu-goto-next-error)
(defalias '+spell/previous-error #'spell-fu-goto-previous-error)
(map! :n "zg" #'+spell/add-word
      :n "zw" #'+spell/remove-word
      :m "[s" #'+spell/previous-error
      :m "]s" #'+spell/next-error)

;; Ligature
(ligature-set-ligatures 'prog-mode '("|||>" "<|||" "<==>" "<!--" "####" "~~>" "***" "||=" "||>"
                                     ":::" "::=" "=:=" "===" "==>" "=!=" "=>>" "=<<" "=/=" "!=="
                                     "!!." ">=>" ">>=" ">>>" ">>-" ">->" "->>" "-->" "---" "-<<"
                                     "<~~" "<~>" "<*>" "<||" "<|>" "<$>" "<==" "<=>" "<=<" "<->"
                                     "<--" "<-<" "<<=" "<<-" "<<<" "<+>" "</>" "###" "#_(" "..<"
                                     "..." "+++" "/==" "///" "_|_" "&&" "^=" "~~" "~@" "~="
                                     "~>" "~-" "**" "*>" "*/" "||" "|}" "|]" "|=" "|>" "|-" "{|"
                                     "[|" "]#" "::" ":=" ":>" ":<" "$>" "==" "=>" "!=" "!!" ">:"
                                     ">=" ">>" ">-" "-~" "-|" "->" "--" "-<" "<~" "<*" "<|" "<:"
                                     "<$" "<=" "<>" "<-" "<<" "<+" "</" "#{" "#[" "#:" "#=" "#!"
                                     "##" "#(" "#?" "#_" "%%" ".=" ".-" ".." ".?" "+>" "++" "?:"
                                     "?=" "?." "??" ";;" "/*" "/=" "/>" "//" "__" "~~" "(*" "*)"
                                     "\\\\" "://"))
(global-ligature-mode t)

;; Org-mode
;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org"
      org-hide-emphasis-markers t
      org-journal-date-prefix "#+TITLE: "
      org-journal-time-prefix "* "
      org-journal-date-format "%a, %Y-%m-%d"
      org-journal-file-format "%Y-%m-%d.org")

(with-eval-after-load 'org
  (global-org-modern-mode)

  (setq alert-default-style 'libnotify
        org-wild-notifier-notification-icon (expand-file-name "~/.local/share/icons-user/Org-mode-unicorn.png")
        alert-fade-time 0
        org-babel-load-languages (cons '(scheme . t) org-babel-load-languages))
  (advice-remove 'org-babel-do-load-languages #'ignore)
  (org-babel-do-load-languages
   'org-babel-load-languages
   org-babel-load-languages)

  (org-wild-notifier-mode)
  (define-advice alert (:before (&rest _) support-sound)
    (start-process "play-alert-sound"
                   nil                  ;buffer
                   "mpv"
                   "--profile=bg"
                   (expand-file-name "~/.local/share/sounds/tuturu.mp3"))))

;; Company
(with-eval-after-load 'company
  (setq company-backends
        '((company-capf
           company-yasnippet
           :separate company-dabbrev-code company-files company-dabbrev))
        company-minimum-prefix-length 1
        company-selection-wrap-around t
        company-idle-delay 0
        company-dabbrev-other-buffers nil
        company-dabbrev-code-other-buffers t
        company-dabbrev-downcase nil
        company-dabbrev-code-ignore-case t
        company-dabbrev-ignore-case t)
  (defvar company-ignore-prefix (make-set '(?? ?_ ? ) :test 'eq))

  (define-advice company--good-prefix-p (:override (prefix min-length) support-ingore-prefix)
    (and (stringp (company--prefix-str prefix)) ;excludes 'stop
         (not (string= prefix ""))
         (let ((len (length prefix)))
           (cond ((or (< len min-length)
                      (element-of-set? (aref prefix 0) company-ignore-prefix))
                  nil)
                 (company--manual-prefix
                  (or (not company-abort-manual-when-too-short)
                      ;; Must not be less than minimum or initial length.
                      (>= len (min company-minimum-prefix-length
                                   (length company--manual-prefix)))))
                 (t (>= len company-minimum-prefix-length))))))

  (defun blank-char-p (char)
    (let ((blank-chars (make-set '(?\s ?\t ?\r ?\n) :test 'eq)))
      (element-of-set? char blank-chars)))

  (define-advice company-indent-or-complete-common (:override (arg) fix-indent)
    (cond ((use-region-p)
           (indent-region (region-beginning) (region-end)))
          ((memq indent-line-function
                 '(indent-relative indent-relative-maybe))
           (company-complete-common))
          ((blank-char-p (char-before)) ;New branch
           (indent-for-tab-command arg))
          ((let ((old-point (point))
                 (old-tick (buffer-chars-modified-tick))
                 (tab-always-indent t))
             (indent-for-tab-command arg)
             (when (and (eq old-point (point))
                        (eq old-tick (buffer-chars-modified-tick)))
               (company-complete-common))))))

  (define-advice company-complete-common-or-cycle (:override (&optional arg next?) fix-select&support-previous)
    (when (company-manual-begin)
      (call-interactively 'company-complete-common)
      ;; remove `buffer-chars-modified-tick' so `company-select-next' can be run
      (let ((company-selection-wrap-around t)
            (current-prefix-arg arg))
        (if next?
            (call-interactively 'company-select-next)
          (call-interactively 'company-select-previous)))))

  (define-key company-mode-map (kbd "<tab>") #'company-indent-or-complete-common)
  (define-key company-active-map (kbd "<tab>") (lambda (&optional arg) (interactive "p")
                                                 (company-complete-common-or-cycle arg t)))
  (define-key company-active-map (kbd "<backtab>") (lambda (&optional arg) (interactive "p")
                                                     (company-complete-common-or-cycle arg nil)))
  (define-key company-active-map (kbd "M-n") nil)
  (define-key company-active-map (kbd "M-p") nil)
  (define-key company-active-map (kbd "C-p") nil)
  (define-key company-active-map (kbd "C-n") nil)
  (define-key company-active-map (kbd "C-w") nil)
  (define-key company-active-map (kbd "C-h") nil)
  (define-key company-active-map (kbd "C-M-s") nil)
  (define-key company-active-map (kbd "M-ESC ESC") nil))

(mapc (lambda (fn) (add-hook 'after-init-hook fn))
      #'(global-company-mode company-statistics-mode))
(require 'company-box)
(add-hook 'company-mode-hook #'company-box-mode)

;; fix for `company-files'
(add-hook 'evil-insert-state-exit-hook (lambda ()
                                         (if (company--active-p)
                                             (company-abort))))

(with-eval-after-load 'company-box
  (setq company-box-enable-icon (boundp 'nerd-icons-font-family)
        company-box-show-single-candidate t
        company-box-backends-colors nil
        company-box-max-candidates 50
        company-box-doc-enable nil)     ;because of the huge doc window
  (setq company-frontends (delq 'company-preview-if-just-one-frontend company-frontends))

  (with-no-warnings
    (define-advice company-box--display (:override (str on-update) display-borders&optimize-performance)
      "Display borders and optimize performance"
      (company-box--render-buffer str on-update)
      (let ((frame (company-box--get-frame))
            (border-color (face-foreground 'font-lock-comment-face nil t)))
        (unless frame
          (setq frame (company-box--make-frame))
          (company-box--set-frame frame))
        (company-box--compute-frame-position frame)
        (company-box--move-selection t)
        (company-box--update-frame-position frame)
        (unless (frame-visible-p frame)
          (make-frame-visible frame))
        (company-box--update-scrollbar frame t)
        (set-face-background 'internal-border border-color frame)
        (when (facep 'child-frame-border)
          (set-face-background 'child-frame-border border-color frame)))
      (with-current-buffer (company-box--get-buffer)
        (company-box--maybe-move-number (or company-box--last-start 1))))

    (defvar company-box-icons-nerd
      `((Unknown . ,(nerd-icons-codicon "nf-cod-symbol_namespace"))
        (Text . ,(nerd-icons-codicon "nf-cod-symbol_string"))
        (Method . ,(nerd-icons-codicon "nf-cod-symbol_method" :face 'nerd-icons-purple))
        (Function . ,(nerd-icons-codicon "nf-cod-symbol_method" :face 'nerd-icons-purple))
        (Constructor . ,(nerd-icons-codicon "nf-cod-symbol_method" :face 'nerd-icons-lpurple))
        (Field . ,(nerd-icons-codicon "nf-cod-symbol_field" :face 'nerd-icons-lblue))
        (Variable . ,(nerd-icons-codicon "nf-cod-symbol_variable" :face 'nerd-icons-lblue))
        (Class . ,(nerd-icons-codicon "nf-cod-symbol_class" :face 'nerd-icons-orange))
        (Interface . ,(nerd-icons-codicon "nf-cod-symbol_interface" :face 'nerd-icons-lblue))
        (Module . ,(nerd-icons-codicon "nf-cod-symbol_namespace" :face 'nerd-icons-lblue))
        (Property . ,(nerd-icons-codicon "nf-cod-symbol_property"))
        (Unit . ,(nerd-icons-codicon "nf-cod-symbol_key"))
        (Value . ,(nerd-icons-codicon "nf-cod-symbol_numeric" :face 'nerd-icons-lblue))
        (Enum . ,(nerd-icons-codicon "nf-cod-symbol_enum" :face 'nerd-icons-orange))
        (Keyword . ,(nerd-icons-codicon "nf-cod-symbol_keyword"))
        (Snippet . ,(nerd-icons-codicon "nf-cod-symbol_snippet"))
        (Color . ,(nerd-icons-codicon "nf-cod-symbol_color"))
        (File . ,(nerd-icons-codicon "nf-cod-symbol_file"))
        (Reference . ,(nerd-icons-codicon "nf-cod-symbol_misc"))
        (Folder . ,(nerd-icons-codicon "nf-cod-folder"))
        (EnumMember . ,(nerd-icons-codicon "nf-cod-symbol_enum_member" :face 'nerd-icons-lblue))
        (Constant . ,(nerd-icons-codicon "nf-cod-symbol_constant"))
        (Struct . ,(nerd-icons-codicon "nf-cod-symbol_structure" :face 'nerd-icons-orange))
        (Event . ,(nerd-icons-codicon "nf-cod-symbol_event" :face 'nerd-icons-orange))
        (Operator . ,(nerd-icons-codicon "nf-cod-symbol_operator"))
        (TypeParameter . ,(nerd-icons-codicon "nf-cod-symbol_class"))
        (Template . ,(nerd-icons-codicon "nf-cod-symbol_snippet"))))
    (setq company-box-icons-alist 'company-box-icons-nerd)))

;; Snippets
(with-eval-after-load 'yasnippet
  (define-key yas-keymap (kbd "<tab>") nil)
  (define-key yas-keymap (kbd "TAB") nil)
  (define-key yas-keymap (kbd "<backtab>") nil)
  (define-key yas-keymap (kbd "S-<tab>") nil)
  (define-key yas-keymap (kbd "C-a") nil)
  (define-key yas-keymap (kbd "C-e") nil)
  (define-key yas-keymap (kbd "C-n") #'yas-next-field-or-maybe-expand)
  (define-key yas-keymap (kbd "C-p") #'yas-prev-field))
(add-hook 'snippet-mode-hook (lambda () (setq-local require-final-newline nil)))
(defun empty-line? ()
  (let ((char-bfr (char-before))
        (char-aft (char-after)))
    (and (not (and (null char-bfr)
                   (null char-aft)))
         (or (eq char-bfr ?\r)
             (eq char-bfr ?\n)
             (null char-bfr))
         (or (eq char-aft ?\r)
             (eq char-aft ?\n)
             (null char-aft)))))
(defun remove-empty-line ()
  (let ((char-bfr (char-before))
        (char-aft (char-after)))
    (if (or (eq char-aft ?\r)
            (eq char-aft ?\n)
            (null char-aft))
        (cond ((eq char-bfr ?\n)
               (progn (delete-char -1)
                      (if (eq (char-before) ?\r)
                          (delete-char -1)
                        nil)))
              ((eq char-bfr ?\r) (delete-char -1))
              (t nil))
      nil)))
(add-hook 'snippet-mode-hook
          (lambda () (add-hook 'before-save-hook
                               (lambda ()
                                 (save-excursion
                                   (goto-char (point-max))
                                   (remove-empty-line)))
                               nil
                               'local)))

;; Indent guides
;; The following example highlighter will highlight normally,
;; except that it will not highlight the first level of indentation:
;; source: https://github.com/DarthFennec/highlight-indent-guides/blob/master/README.md#custom-highlighter-function
(defun my/indent-guide-highlighter (level responsive display)
  (if (> 1 level)
      nil
    (highlight-indent-guides--highlighter-default level responsive display)))
(setq highlight-indent-guides-highlighter-function #'my/indent-guide-highlighter)

(setq highlight-indent-guides-auto-enabled nil)
(defun lighten-hex (hex percent)
  "Lighten a given hexadecimal color by a percentage."
  (let* ((r (string-to-number (substring hex 1 3) 16))
         (g (string-to-number (substring hex 3 5) 16))
         (b (string-to-number (substring hex 5 7) 16))
         (alpha (- 1 (/ percent 100.0)))
         (bg 255)
         (calculate (lambda (n)
                      (round (+ (* (- 1 alpha) bg) (* alpha n))))))
    (format "#%02x%02x%02x" (funcall calculate r) (funcall calculate g) (funcall calculate b))))
(defun set-color-for-highlight-indent-guides (val)
  (set-face-foreground 'highlight-indent-guides-character-face
                       (let ((comment-face (face-attribute 'font-lock-comment-face :foreground)))
                         (unless (eq comment-face 'unspecified)
                           (lighten-hex comment-face val)))))
(with-eval-after-load 'highlight-indent-guides
  (let* ((current-time (decode-time))
         (hour (nth 2 current-time))
         (val (if (and (>= hour 6) (< hour 18))
                  40
                -40)))
    (set-color-for-highlight-indent-guides val)))
(run-at-time "06:00"
             (* 24 60 60)
             (lambda () (set-color-for-highlight-indent-guides 40)))
(run-at-time "18:00"
             (* 24 60 60)
             (lambda () (set-color-for-highlight-indent-guides -40)))

;; Symbol highlight & rename
(require 'symbol-overlay)
(define-key evil-normal-state-map (kbd "M-n") #'symbol-overlay-jump-next)
(define-key evil-normal-state-map (kbd "M-p") #'symbol-overlay-jump-prev)
(mapc (lambda (orig-fn) (advice-add orig-fn :after #'my/center-line))
      '(symbol-overlay-jump-next symbol-overlay-jump-prev))
(map! :leader "r r" #'symbol-overlay-rename)
(map! :leader "r q" #'symbol-overlay-query-replace)
(advice-add 'symbol-overlay-query-replace :after #'symbol-overlay-remove-all)
(global-set-key (kbd "<f7>") #'symbol-overlay-mode)
(global-set-key (kbd "<f8>") #'symbol-overlay-remove-all)
;; (add-hook 'find-file-hook #'symbol-overlay-mode)

;; Structure editing
(defun geiser-repl? (buf)
  (let ((str (buffer-name buf)))
    (and (length> str 17)
         (equal (substring str 0 17) "*Geiser Chez REPL")
         (or (equal (substring str -1 nil) "*")
             (equal (substring str 17 18) "*")))))
(defun geiser-close-repl ()
  (interactive)
  (defun close-process (buf)
    (if (get-buffer-process buf)
        (delete-process buf)
      nil))
  (dolist (buf (buffer-list))
    (if (geiser-repl? buf)
        (progn (delete-windows-on buf nil)
               (close-process buf)
               (kill-buffer buf))
      nil)))
(defun geiser-open-repl ()
  (interactive)
  (let ((buf (current-buffer)))
    (if (null (cl-member-if #'geiser-repl? (buffer-list)))
        (progn (geiser 'chez)
               (window-resize (selected-window) -10)
               (switch-to-buffer-other-window buf))
      nil)))

(require 'f)
(progn (let ((fennel-mode-path (expand-file-name "~/.config/emacs/.local/straight/repos/fennel-mode")))
         (autoload 'fennel-mode (f-join fennel-mode-path "fennel-mode") nil t)
         (autoload 'antifennel-mode (f-join fennel-mode-path "antifennel.el") nil t))
       (add-to-list 'auto-mode-alist '("\\.fnl\\'" . fennel-mode))
       (add-hook 'lua-mode-hook 'antifennel-mode))

(progn (add-hook 'scheme-mode-hook #'geiser-mode)
       (mapc (lambda (hook) (add-hook hook #'lispy-mode))
             '(scheme-mode-hook geiser-repl-mode-hook emacs-lisp-mode-hook fennel-mode-hook)))

(setq scheme-program-name "chez"
      geiser-chez-binary "chez"
      geiser-repl-window-allow-split nil
      geiser-mode-start-repl-p t
      geiser-repl-query-on-kill-p nil)
;; (setq geiser-active-implementations '(chez))

(defun conditionally-enable-lispy ()
  (when (eq this-command 'eval-expression)
    (lispy-mode 1)))
(add-hook 'minibuffer-setup-hook #'conditionally-enable-lispy)

(defun closed-pair-p (char)
  (let ((closed-pairs (make-set '(?\) ?\] ?\}) :test 'eq)))
    (element-of-set? char closed-pairs)))

(defun opened-pair-p (char)
  (let ((opened-pairs (make-set '(?\( ?\[ ?\{) :test 'eq)))
    (element-of-set? char opened-pairs)))

(define-advice eros-eval-last-sexp (:around (orig-fun &rest args) support-next-sexp)
  (if (opened-pair-p (char-after))
      (save-excursion
        (forward-sexp)
        (if (closed-pair-p (char-after))
            (forward-char -1))
        (apply orig-fun args))
    (apply orig-fun args)))

(with-eval-after-load 'geiser
  (advice-remove 'geiser-eval-last-sexp #'evil-collection-geiser-last-sexp)
  (define-advice geiser-eval-last-sexp (:around (orig-fun &rest args) support-next-sexp)
    (cond ((opened-pair-p (char-after))
           (save-excursion
             (forward-sexp)
             (apply orig-fun args)))
          ((or (evil-normal-state-p) (evil-motion-state-p))
           (save-excursion
             (forward-char)
             (apply orig-fun args)))
          (t (apply orig-fun args)))))

(with-eval-after-load 'lispy
  (define-advice lispy-raise-some (:override () consistent-right)
    (let ((pt (point)))
      (cond ((region-active-p))
            ((lispy-left-p)
             (if (null (lispy--out-forward 1))
                 (progn
                   (goto-char pt)
                   (lispy-complain "Not enough depth to raise"))
               (backward-char 1)
               (set-mark (point))
               (goto-char pt)))
            ((lispy-right-p)
             (if (null (lispy--out-forward 1))
                 (progn
                   (goto-char pt)
                   (lispy-complain "Not enough depth to raise"))
               (backward-list)
               (forward-char 1)
               (down-list 1)            ;more proper way
               (forward-char -1)
               (set-mark (point))
               (goto-char pt)))
            (t
             (error "Unexpected")))
      (lispy-raise 1)
      (deactivate-mark)))

  (define-advice lispy-kill-at-point (:override (&optional dont-kill) support-dont-kill -1)
    (if (region-active-p)
        (lispy--maybe-safe-kill-region (region-beginning)
                                       (region-end))
      (let ((bnd (or (lispy--bounds-comment)
                     (lispy--bounds-string)
                     (lispy--bounds-list)
                     (and (derived-mode-p 'text-mode)
                          (cons (save-excursion
                                  (1+ (re-search-backward "[ \t\n]" nil t)))
                                (save-excursion
                                  (1- (re-search-forward "[ \t\n]" nil t))))))))
        (if (or buffer-read-only dont-kill) ;support copy
            (kill-new (buffer-substring
                       (car bnd) (cdr bnd)))
          (kill-region (car bnd) (cdr bnd))))))

  (define-advice sp-kill-sexp (:around (orig-fun &optional arg dont-kill) auto-dont-kill -1)
    (if buffer-read-only
        (funcall orig-fun arg t)
      (funcall orig-fun arg dont-kill)))

  (defun lispy-kill-at-point-fix (&optional arg dont-kill)
    "Kill any atoms or lists beside cursor"
    (interactive "P")
    (let ((left (char-before))
          (right (char-after)))
      (cond ((eq left ?\")          ;when the cursor is at the right of a string
             (save-excursion
               (forward-char -1)        ;properly mark strings
               (lispy-kill-at-point dont-kill)))
            ((or (closed-pair-p left)   ;kill the inner nearest list
                 (opened-pair-p right)  ;preserve quotes '
                 (cursor-in-string-or-comment-p))
             (lispy-kill-at-point dont-kill))
            ((or (eq right ? )          ;kill the nearest atom in a list
                 (closed-pair-p right)) ;left atoms or lists take precedence in closed )) places
             (save-excursion
               (forward-char -1)
               (sp-kill-sexp arg dont-kill)))
            (t
             (sp-kill-sexp arg dont-kill))))) ;properly kill non-string atoms in a list
  (evil-define-key 'insert lispy-mode-map (kbd "C-,") #'lispy-kill-at-point-fix)

  (defun lispy-copy-at-point (&optional arg)
    (interactive "P")
    (lispy-kill-at-point-fix arg t))
  (evil-define-key 'insert lispy-mode-map (kbd "C-y") #'lispy-copy-at-point)

  ;; `lispy-delete'
  (define-key evil-insert-state-map (kbd "C-d") nil)

  ;; fix C-k
  (evil-define-key 'insert lispy-mode-map (kbd "C-k") #'lispy-kill)

  (defun cursor-in-string-or-comment-p ()
    (let ((parse-state (syntax-ppss)))
      (or (nth 3 parse-state)
          (nth 4 parse-state))))

  ;; fix backslash
  (defun after-backslash? ()
    (defun iter (n)
      (if (eq (char-before) ?\\)
          (save-excursion
            (forward-char -1)
            (iter (1+ n)))
        n))
    (cl-oddp (iter 0)))

  ;; fix [] in strings and comments
  (defun lispy-square-bracket (char)
    (interactive "*")
    (if (or (cursor-in-string-or-comment-p)
            (after-backslash?))
        (insert char)
      (let ((table #s(hash-table
                      size 2
                      test equal
                      data ("[" #'lispy-backward
                            "]" #'lispy-forward))))
        (call-interactively (cadr (gethash char table)))))) ;extract funtion from ('function . 'the-name) for #s syntax
  (define-key lispy-mode-map-lispy (kbd "[")
              (lambda () (interactive) (lispy-square-bracket "[")))
  (define-key lispy-mode-map-lispy (kbd "]")
              (lambda () (interactive) (lispy-square-bracket "]"))))

(with-eval-after-load 'lispyville
  ;; Key themes
  (lispyville-set-key-theme
   '((operators normal)
     c-w
     c-u
     prettify
     (atom-movement normal visual)
     commentary
     slurp/barf-lispy
     additional
     additional-insert))

  ;; `lispy' functions in normal mode
  (defun my/lispyville-fix (f &rest args)
    "Avoid unexpected results caused by different cursor position in normal mode"
    (if (closed-pair-p (char-after))
        (save-excursion
          (forward-char 1)
          (apply f args))
      (apply f args)))

  (defun lispyville-raise ()
    (interactive)
    (my/lispyville-fix #'lispy-raise-sexp))
  (evil-define-key 'normal lispyville-mode-map (kbd "M-r") #'lispyville-raise)

  (defun lispyville-raise-some ()
    (interactive)
    (my/lispyville-fix #'lispy-raise-some))
  (evil-define-key 'normal lispyville-mode-map (kbd "M-R") #'lispyville-raise-some)

  (defun lispyville-kill-at-point (&optional arg dont-kill)
    (interactive "*P")
    (my/lispyville-fix #'lispy-kill-at-point-fix arg dont-kill))
  (evil-define-key 'normal lispyville-mode-map (kbd "C-,") #'lispyville-kill-at-point)

  (defun lispyville-copy-at-point (&optional arg)
    (interactive "P")
    (my/lispyville-fix #'lispy-copy-at-point arg))
  (evil-define-key 'normal lispyville-mode-map (kbd "C-y") #'lispyville-copy-at-point)
  (define-key evil-motion-state-map (kbd "C-y")
              (lambda () (interactive)
                (if helpful-mode
                    (call-interactively #'lispyville-copy-at-point)
                  (call-interactively #'evil-scroll-line-up))))
  (defvar helpful-mode nil)
  (make-variable-buffer-local 'helpful-mode)
  (add-hook 'helpful-mode-hook (lambda () (setq-local helpful-mode t)))

  (defun lispville-splice (arg)
    (interactive "p")
    (my/lispyville-fix #'lispy-splice arg))
  (evil-define-key 'normal lispyville-mode-map (kbd "M-s") #'lispville-splice)

  (defun lispyville-clone (arg)
    (interactive "p")
    (my/lispyville-fix #'lispy-clone arg)
    (if (closed-pair-p (char-after))
        (progn (forward-char)           ;fix movement
               (forward-sexp))))
  (evil-define-key 'normal lispyville-mode-map (kbd "M-c") #'lispyville-clone)

  (defun lispyville-convolute (arg)
    (interactive "p")
    (my/lispyville-fix #'lispy-convolute arg))
  (evil-define-key 'normal lispyville-mode-map (kbd "M-C") #'lispyville-convolute))

;; Scratch
(setq doom-scratch-initial-major-mode t)
(add-variable-watcher 'doom-scratch-buffers
                      (lambda (symbol newval operation where)
                        (mapcar
                         (lambda (buf)
                           (if (not (null (buffer-name buf)))
                               (with-current-buffer buf
                                 (if (not lexical-binding)
                                     (setq-local lexical-binding t)))))
                         newval)))

;; Magit
(with-eval-after-load 'magit
  (setf (alist-get 'unpushed magit-section-initial-visibility-alist) 'show) ;expand `Recent commits`
  (put 'magit-log-mode 'magit-log-default-arguments '("--graph" "-n256" "--decorate" "--color" "--show-signature")))

;; Avoid a redundant newline introduced by `open-line' in `git-commit-setup'
(add-hook 'git-commit-setup-hook (lambda ()
                                   (ignore-error user-error (undo))
                                   (setq-local buffer-undo-list nil)
                                   (set-buffer-modified-p nil)))

;; Display line numbers in `git-rebase-mode'
(add-hook 'git-rebase-mode-hook (lambda ()
                                  (setq-local magit-section-disable-line-numbers nil)
                                  (display-line-numbers-mode)))

;; Make 'gg' work under `git-rebase-mode'
;; Note: 1. Need to wait for `git-rebase-mode-map'
;;       2. `evil-motion-state-map' makes no sense here
(add-hook 'git-rebase-mode-hook (lambda ()
                                  (evil-define-key 'normal 'local
                                    (kbd "g g") #'evil-goto-first-line)))

;; ssh-agent
(with-eval-after-load 'magit
  (push (format "SSH_AUTH_SOCK=%s/ssh-agent.socket"
                (getenv "XDG_RUNTIME_DIR"))
        magit-git-environment))

;; Magit/yadm
(defun find-git-root (dir)
  (cond ((f-dir? (f-join dir ".git")) dir)
        ((f-equal? dir "/") nil)
        (t (find-git-root (f-dirname dir)))))

(with-eval-after-load 'magit
  (define-advice magit-process-environment (:filter-return (env) add-git-dir)
    "Inspired by https://github.com/magit/magit/issues/460#issuecomment-1475082958.
This implementation requires users to set `core.worktree` and make sure that `core.bare` is not `true` since git doesn't allow `core.worktree` to exist when `core.bare` is set to `true`"
    (let* ((home (expand-file-name "~"))
           (git-dir (f-join home ".local/share/yadm/repo.git"))
           (default-branch "develop")
           (get-branch-name (lambda ()
                              (let ((p (run-process
                                        (list "git"
                                              (format "--git-dir=%s" git-dir)
                                              "branch-name"))))
                                (if (not (= (status-process p) 0))
                                    default-branch ;Custom command is not available at HEAD
                                  (s-trim-right (output-process p))))))
           (get-tracked-dirs (lambda (home git-dir cwd)
                               (let ((p (run-process
                                         (list "git"
                                               (format "--git-dir=%s" git-dir)
                                               "ls-dirs"
                                               home
                                               "--tree-ish"
                                               "HEAD"
                                               "--tree-ish"
                                               (funcall get-branch-name)))))
                                 (let ((status (status-process p)))
                                   (if (= status 0)
                                       (mapcar (lambda (d) (f-join cwd d))
                                               (split-string
                                                (s-trim-right
                                                 (output-process p))
                                                "\n"))
                                     'error)))))) ;Custom command is not available at HEAD
      (when (and (f-dir? git-dir)
                 (let ((cwd (expand-file-name default-directory)))
                   (or (f-equal? cwd home)
                       (and (null (find-git-root cwd))
                            (let ((res (funcall get-tracked-dirs home git-dir cwd)))
                              (if (eq res 'error)
                                  t
                                (element-of-set? (directory-file-name cwd)
                                                 (make-set res))))))))
        (push (format "GIT_DIR=%s" git-dir) env)))
    env))

;; Project
(setq projectile-project-search-path '(("~/dm/pj" . 1)))

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.
