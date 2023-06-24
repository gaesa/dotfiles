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
(set-face-attribute 'italic nil         ;affects M-x function descriptions & org-mode
                     :slant 'italic
                     :underline nil
                     :family "JetBrains Mono")
(custom-set-faces!                      ;affects comments in source codes
  '(font-lock-comment-face :slant italic :underline nil :family "JetBrains Mono"))

;;
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

;; Remap
(define-key evil-insert-state-map (kbd "C-S-v") #'clipboard-yank)
(define-key evil-normal-state-map (kbd "C-i") #'better-jumper-jump-forward)
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

(defun my/center-line (&rest _)
  (evil-scroll-line-to-center nil))
(advice-add 'evil-search-next :after #'my/center-line) ;; n -> nzz
(advice-add 'evil-search-previous :after #'my/center-line) ;; N -> nzz
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

;; Line wrap
(+global-word-wrap-mode t)

;; Remove annoying tildes
(remove-hook 'prog-mode-hook #'vi-tilde-fringe-mode)
(remove-hook 'text-mode-hook #'vi-tilde-fringe-mode)
(remove-hook 'conf-mode-hook #'vi-tilde-fringe-mode)

;; Disable silly exit prompt
(setq confirm-kill-emacs nil)

;; Window
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;; Make clipboard can be accessed in both terminal and GUI
(setq-default wl-copy-process nil)
(when (string-prefix-p "wayland" (getenv "WAYLAND_DISPLAY"))
  (defun wl-copy-handler (text)
    (setq wl-copy-process (make-process :name "wl-copy"
                                        :buffer nil
                                        :command '("wl-copy" "-f")
                                        :connection-type 'pipe))
    (process-send-string wl-copy-process text)
    (process-send-eof wl-copy-process))
  (defun wl-paste-handler ()
    (if (and wl-copy-process (process-live-p wl-copy-process))
        nil                 ; should return nil if we're the current paste owner
      (shell-command-to-string "wl-paste -n")))
  (setq interprogram-cut-function 'wl-copy-handler
        interprogram-paste-function 'wl-paste-handler))

;; Input method
(setq fcitx-remote-command "fcitx5-remote")

;; Org-mode
;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
(setq org-hide-emphasis-markers t)

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
(after! highlight-indent-guides
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

;; Scheme & other lisp
(progn (add-hook 'scheme-mode-hook #'smartparens-strict-mode)
       (add-hook 'scheme-mode-hook #'geiser-mode)
       (add-hook 'scheme-mode-hook (lambda () (lispy-mode 1)))
       (add-hook 'emacs-lisp-mode-hook #'smartparens-strict-mode)
       (add-hook 'emacs-lisp-mode-hook (lambda () (lispy-mode 1))))
(setq scheme-program-name "chez")
(setq geiser-chez-binary "chez")
;(setq geiser-active-implementations '(chez))

(defun conditionally-enable-lispy ()
  (when (eq this-command 'eval-expression)
    (lispy-mode 1)))
(add-hook 'minibuffer-setup-hook 'conditionally-enable-lispy)

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
