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
(require 'nerd-icons)
(setq doom-font (font-spec :family "monospace" :size 25 :height 1.25)
      doom-variable-pitch-font (font-spec :family "sans-serif" :size 25 :height 1.25))
(set-face-attribute 'italic nil         ;affects M-x function descriptions & org-mode
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
(add-to-list 'custom-theme-load-path "~/.config/emacs/everforest-theme")

(defun switch-theme-light ()
  (load-theme 'everforest-hard-light t)
  (enable-theme 'everforest-hard-light))
(defun switch-theme-dark ()
  (load-theme 'everforest-hard-dark t)
  (enable-theme 'everforest-hard-dark))
(defun switch-theme (&optional color)
  (if (null color)
      (let* ((current-time (decode-time))
             (hour (nth 2 current-time)))
        (if (and (>= hour 6) (< hour 18))
            (switch-theme-light)
          (switch-theme-dark)))
    (let ((colors #s(hash-table size 2
                                test equal
                                data (
                                      "light" t
                                      "dark" t))))
      (if (gethash color colors)
          (funcall (intern (format "switch-theme-%s" color)))
        (error "Invalid color: %s" color)))))

(add-hook 'after-init-hook #'switch-theme)
;': refer symbols as itself instead of the stored value
;This is a symbol list instead of a function call: '()
;#': like `'`, but it is only used for function reference

(run-at-time "06:00" (* 24 60 60) (lambda () (switch-theme "light")))
(run-at-time "18:00" (* 24 60 60) (lambda () (switch-theme "dark")))
;Sexps starting with lambda are treated as function objects themselves,
;as only function definitions exist here, and no function calls are present.

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
      kill-ring-max 50)

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

(mapcar (lambda (func) (advice-add func :around #'my/evil-clipboard))
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

(defun my/center-line (&rest _)
  (evil-scroll-line-to-center nil))
(advice-add 'evil-search-next :after #'my/center-line) ;; n -> nzz
(advice-add 'evil-ex-search-next :after #'my/center-line) ;; n -> nzz
(advice-add 'evil-search-previous :after #'my/center-line) ;; N -> Nzz
(advice-add 'evil-ex-search-previous :after #'my/center-line) ;; N -> Nzz
(advice-add 'evil-next-visual-line :after #'my/center-line) ;; gj -> gjzz
(advice-add 'evil-previous-visual-line :after #'my/center-line) ;; gk -> gjzz
(advice-add 'evil-scroll-up :after #'my/center-line) ;; C-u -> C-u zz
(advice-add 'evil-scroll-down :after #'my/center-line) ;; C-d -> C-d zz
(advice-add 'better-jumper-jump-forward :after #'my/center-line) ;; C-i -> C-o zz
(advice-add 'better-jumper-jump-backward :after #'my/center-line) ;; C-o -> C-o zz
(advice-add 'evil-ex-search-word-forward :after #'my/center-line) ;; * -> *zz
(advice-add 'evil-ex-search-word-backward :after #'my/center-line) ;; # -> #zz
(advice-add 'evil-goto-line :after #'my/center-line) ;; G -> Gzz
(advice-add 'evil-jump-item :after #'my/center-line) ;; % -> %zz
(advice-add '+lookup/definition :after #'my/center-line) ;; gd -> gdzz
(advice-add '+lookup/references :after #'my/center-line) ;; gD -> gDzz

;; Line wrap
(+global-word-wrap-mode t)

;; Disable silly exit prompt
(setq confirm-kill-emacs nil)

;; Window
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Input method
(setq fcitx-remote-command "fcitx5-remote")

;; Spell
(setq ispell-check-comments nil)
(setq spell-fu-idle-delay 0)
(setq spell-fu-faces-exclude '(font-lock-comment-face))
;; default path doesn't respect XDG
;; (setq ispell-personal-dictionary (expand-file-name "~/.config/dict/en"))
(add-hook 'spell-fu-mode-hook
  (lambda ()
    (spell-fu-dictionary-add (spell-fu-get-ispell-dictionary "en"))
    (spell-fu-dictionary-add
     (spell-fu-get-personal-dictionary "en-personal" (expand-file-name "~/.config/dict/en")))))

(setq spell-mode-alist '((git-commit-mode . (git-commit-comment-file
                                             git-commit-comment-action
                                             git-commit-comment-heading
                                             git-commit-comment-detached
                                             git-commit-comment-branch
                                             git-commit-comment-branch-local
                                             git-commit-comment-branch-remote))
                         (org-mode . (org-block-begin-line
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
(advice-add 'spell-fu-word-add :after #'re-enable-spell)
(advice-add 'spell-fu-word-remove :after #'re-enable-spell)

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
;; fix org-mode check
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
(setq org-directory "~/org/")
(setq org-hide-emphasis-markers t)
(setq alert-default-style 'libnotify)
(setq org-wild-notifier-notification-icon (expand-file-name "~/.local/share/icons-user/Org-mode-unicorn.png"))
(setq alert-fade-time 0)
(org-wild-notifier-mode)
(defun play-alert-sound (&rest _)
  (start-process "play-alert-sound"
                 nil                    ;buffer
                 "mpv"
                 "--profile=bg"
                 (expand-file-name "~/.local/share/sounds/tuturu.mp3")))
(advice-add 'alert :before #'play-alert-sound)

(add-hook 'org-mode-hook #'org-modern-mode)
(add-hook 'org-agenda-finalize-hook #'org-modern-agenda)

;; Company
(with-eval-after-load 'company
  (setq company-backends
        '((company-capf
           company-yasnippet
           :separate company-dabbrev-code company-files company-dabbrev))
        company-minimum-prefix-length 1
        company-ignore-prefix #s(hash-table size 2
                                            test eq
                                            data (
                                                  ?? t
                                                  ?_ t))
        company-selection-wrap-around t
        company-idle-delay 0
        company-dabbrev-other-buffers nil
        company-dabbrev-code-other-buffers t
        company-dabbrev-downcase nil
        company-dabbrev-code-ignore-case t
        company-dabbrev-ignore-case t)

  (defun company--good-prefix-p (prefix)
    (and (stringp (company--prefix-str prefix)) ;excludes 'stop
         (let ((len (length prefix)))
           (if (and (> len 1)
                    (gethash (aref prefix 0) company-ignore-prefix))
               nil
             (if company--manual-prefix
                 (or (not company-abort-manual-when-too-short)
                     ;; Must not be less than minimum or initial length.
                     (>= len (min company-minimum-prefix-length
                                  (length company--manual-prefix))))
               (>= len company-minimum-prefix-length))))))


  (defun blank-char? (char)
    (let ((blank-char #s(hash-table size 4
                                    test eq
                                    data (
                                          ?\s t
                                          ?\t t
                                          ?\r t
                                          ?\n t))))
      (not (null (gethash char blank-char)))))

  (defun my/company-indent-or-complete-common (arg)
    "Indent the current line or region, or complete the common part."
    (interactive "P")
    (cond
     ((use-region-p)
      (indent-region (region-beginning) (region-end)))
     ((memq indent-line-function
            '(indent-relative indent-relative-maybe))
      (company-complete-common))
     ((blank-char? (char-before))       ;New branch
      (indent-for-tab-command arg))
     ((let ((old-point (point))
            (old-tick (buffer-chars-modified-tick))
            (tab-always-indent t))
        (indent-for-tab-command arg)
        (when (and (eq old-point (point))
                   (eq old-tick (buffer-chars-modified-tick)))
          (company-complete-common))))))

  (defun my/company-complete-common-or-cycle-next (&optional arg)
    "Insert the common part of all candidates, or select the next one.
       With ARG, move by that many elements."
    (interactive "p")
    (when (company-manual-begin)
      (call-interactively 'company-complete-common)
      ;; remove `buffer-chars-modified-tick' so `company-select-next' can be run
      (let ((company-selection-wrap-around t)
            (current-prefix-arg arg))
        (call-interactively 'company-select-next))))

  (defun my/company-complete-common-or-cycle-previous (&optional arg)
    "Insert the common part of all candidates, or select the previous one.
       With ARG, move by that many elements."
    (interactive "p")
    (when (company-manual-begin)
      (call-interactively 'company-complete-common)
      (let ((current-prefix-arg arg))
        (call-interactively 'company-select-previous))))

  (define-key company-mode-map (kbd "<tab>") #'my/company-indent-or-complete-common)
  (define-key company-active-map (kbd "<tab>") #'my/company-complete-common-or-cycle-next)
  (define-key company-active-map (kbd "<backtab>") #'my/company-complete-common-or-cycle-previous)
  (define-key company-active-map (kbd "M-n") nil)
  (define-key company-active-map (kbd "M-p") nil)
  (define-key company-active-map (kbd "C-p") nil)
  (define-key company-active-map (kbd "C-n") nil)
  (define-key company-active-map (kbd "C-w") nil)
  (define-key company-active-map (kbd "C-h") nil)
  (define-key company-active-map (kbd "C-M-s") nil)
  (define-key company-active-map (kbd "M-ESC ESC") nil))

(add-hook 'after-init-hook #'global-company-mode)
(add-hook 'after-init-hook #'company-statistics-mode)
(require 'company-box)
(add-hook 'company-mode-hook #'company-box-mode)

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
                       (lighten-hex (face-attribute 'font-lock-comment-face :foreground) val)))
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
(advice-add 'symbol-overlay-jump-next :after #'my/center-line)
(advice-add 'symbol-overlay-jump-prev :after #'my/center-line)
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

(progn (add-hook 'scheme-mode-hook #'geiser-mode)
       (add-hook 'scheme-mode-hook #'lispy-mode)
       (add-hook 'geiser-repl-mode-hook #'lispy-mode)
       (add-hook 'emacs-lisp-mode-hook #'lispy-mode))

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
  (let ((closed-pairs
         #s(hash-table
            size 3
            test eq
            data (
                  ?\) t
                  ?\] t
                  ?\} t))))
    (gethash char closed-pairs)))

(defun opened-pair-p (char)
  (let ((opened-pairs
         #s(hash-table
            size 3
            test eq
            data (
                  ?\( t
                  ?\[ t
                  ?\{ t))))
    (gethash char opened-pairs)))

(define-advice eros-eval-last-sexp (:around (orig-fun &rest args) support-next-sexp)
  (if (opened-pair-p (char-after))
      (save-excursion
        (forward-sexp)
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
                 (let ((lst (syntax-ppss)))
                   (or (nth 3 lst)      ;kill whole strings
                       (nth 4 lst))))   ;kill whole comments
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
  (evil-define-key 'insert lispy-mode-map (kbd "C-k") #'lispy-kill))

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

;; Magit
;; expand `Recent commits`
(setf (alist-get 'unpushed magit-section-initial-visibility-alist) 'show)

;; Avoid a redundant newline introduced by `open-line' in `git-commit-setup'
(add-hook 'git-commit-setup-hook (lambda ()
                                   (undo)
                                   (setq-local buffer-undo-list nil)
                                   (set-buffer-modified-p nil)))

;; Display line numbers in `git-rebase-mode'
(add-hook 'git-rebase-mode-hook (lambda ()
                                  (setq-local magit-section-disable-line-numbers nil)
                                  (display-line-numbers-mode)))
;; ssh-agent
(with-eval-after-load 'magit
  (push (format "SSH_AUTH_SOCK=%s/ssh-agent.socket"
                (or (getenv "XDG_RUNTIME_DIR")
                    (format "/run/user/%s" (user-uid))))
        magit-git-environment))

;; Magit/yadm
(defun find-git-root (dir)
  (cond ((file-directory-p (expand-file-name ".git" dir)) dir)
        ((string= dir "/") nil)
        (t (find-git-root (directory-file-name
                           (file-name-directory dir))))))
(defun my/git-dir-hook ()
  (with-eval-after-load 'magit
    (let* ((myconf-path (expand-file-name "~/.local/share/yadm/repo.git"))
           (git-arg (format "--git-dir=%s" myconf-path)))
      (if (and (file-exists-p myconf-path)
               (null (find-git-root (expand-file-name default-directory))))
          (if (member git-arg magit-git-global-arguments)
              nil
            (add-to-list 'magit-git-global-arguments git-arg))
        (if (member git-arg magit-git-global-arguments)
            (setq magit-git-global-arguments (remove git-arg magit-git-global-arguments))
          nil)))))
(add-hook 'window-buffer-change-functions (lambda (_) (my/git-dir-hook)))
;; (add-hook 'find-file-hook (lambda () (my/git-dir-hook)))
;; triggered only once after a file is loaded into the buffer

;; DONT WORK:
;; Disable lispy-comment for specific files
;; (defun my/disable-lispy-comment ()
;;   (when (string= (buffer-file-name) (expand-file-name "~/.config/doom/init.el"))
;;     (define-key lispy-mode-map (kbd ";") nil)))
;; (add-hook 'find-file-hook #'my/disable-lispy-comment)
;; (eval-after-load "lispy"
;;   `(progn
;;      (define-key lispy-mode-map (kbd ";") nil)))

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
