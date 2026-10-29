;;; init.el --- Declarative terminal Emacs configuration -*- lexical-binding: t; -*-

(defconst islands-emacs-cache-directory
  (file-name-as-directory
   (expand-file-name
    "emacs"
    (or (getenv "XDG_CACHE_HOME")
        (expand-file-name "~/.cache")))))

(let ((backup-directory
       (expand-file-name "backups/" islands-emacs-cache-directory))
      (auto-save-directory
       (expand-file-name "auto-save/" islands-emacs-cache-directory))
      (lock-directory
       (expand-file-name "locks/" islands-emacs-cache-directory)))
  (dolist (directory
           (list backup-directory auto-save-directory lock-directory))
    (make-directory directory t)
    (set-file-modes directory #o700))

  (setq backup-directory-alist `(("." . ,backup-directory))
        auto-save-file-name-transforms
        `((".*" ,auto-save-directory sha256))
        lock-file-name-transforms
        `((".*" ,lock-directory sha256))))

(setq custom-file (expand-file-name "custom.el" islands-emacs-cache-directory))
(load custom-file t)

(setq display-line-numbers-type 'relative
      eshell-history-isearch t)
(global-display-line-numbers-mode 1)
(column-number-mode 1)
(electric-pair-mode 1)

(add-to-list 'custom-theme-load-path "@emacsConfigDirectory@/themes")
(mapc #'disable-theme custom-enabled-themes)
(load-theme 'islands-dark-transparent t)

(use-package ace-window
  :ensure t
  :commands ace-window)

(use-package magit
  :ensure t
  :commands magit)

(use-package vterm
  :ensure t
  :commands vterm)

(use-package nix-mode
  :ensure t
  :defer t)

(use-package nix-ts-mode
  :ensure t
  :defer t)

(use-package markdown-ts-mode
  :ensure nil
  :defer t)

(use-package which-key
  :ensure t
  :custom
  (which-key-idle-delay 0.1)
  :config
  (which-key-mode 1))

(defconst islands-typescript-language-server "@typescriptLanguageServer@")
(defconst islands-rust-analyzer "@rustAnalyzer@")
(defconst islands-clangd "@clangd@")
(defconst islands-basedpyright "@basedpyright@")
(defconst islands-nixd "@nixd@")
(defconst islands-vscode-json-language-server
  "@vscodeJsonLanguageServer@")
(defconst islands-taplo "@taplo@")
(defconst islands-marksman "@marksman@")
(defconst islands-bash-language-server "@bashLanguageServer@")

(defconst islands-prettier "@prettier@")
(defconst islands-rustfmt "@rustfmt@")
(defconst islands-clang-format "@clangFormat@")
(defconst islands-ruff "@ruff@")
(defconst islands-nixfmt "@nixfmt@")
(defconst islands-shfmt "@shfmt@")

(dolist (association
         '(("\\.ts\\'" . typescript-ts-mode)
           ("\\.tsx\\'" . tsx-ts-mode)
           ("\\.\\(?:js\\|mjs\\|cjs\\|jsx\\)\\'" . js-ts-mode)
           ("\\.rs\\'" . rust-ts-mode)
           ("\\.c\\'" . c-ts-mode)
           ("\\.h\\'" . c-ts-mode)
           ("\\.\\(?:cc\\|cpp\\|cxx\\|hh\\|hpp\\|hxx\\)\\'"
            . c++-ts-mode)
           ("\\.py\\'" . python-ts-mode)
           ("\\.nix\\'" . nix-ts-mode)
           ("\\.json\\'" . json-ts-mode)
           ("\\.toml\\'" . toml-ts-mode)
           ("\\.\\(?:md\\|markdown\\)\\'" . markdown-ts-mode)
           ("\\.\\(?:sh\\|bash\\)\\'" . bash-ts-mode)))
  (add-to-list 'auto-mode-alist association))

(defconst islands-eglot-modes
  '(typescript-ts-mode tsx-ts-mode js-ts-mode rust-ts-mode c-ts-mode
    c++-ts-mode python-ts-mode nix-ts-mode json-ts-mode toml-ts-mode
    markdown-ts-mode bash-ts-mode))

(defun islands-eglot-ensure ()
  "Start Eglot without making an ordinary buffer fail to open."
  (condition-case error-data
      (eglot-ensure)
    (error
     (message "Eglot could not start: %s"
              (error-message-string error-data)))))

(defun islands-enable-eglot-inlay-hints ()
  "Show server-provided inlay hints when this Emacs supports them."
  (when (fboundp 'eglot-inlay-hints-mode)
    (eglot-inlay-hints-mode 1)))

(defun islands-rust-eglot-settings ()
  "Match the Rust Analyzer settings used by the Helix configuration."
  (setq-local
   eglot-workspace-configuration
   '(:rust-analyzer
     (:check (:command "clippy" :allTargets t)
      :cargo (:buildScripts (:enable t))
      :procMacro (:enable t)
      :completion (:fullFunctionSignatures (:enable t))
      :imports (:granularity (:group "module"))
      :inlayHints
      (:bindingModeHints (:enable t)
       :closureReturnTypeHints (:enable "with_block")
       :lifetimeElisionHints (:enable "skip_trivial"
                              :useParameterNames t))))))

(use-package eglot
  :ensure nil
  :config
  (dolist (contact
           `(((typescript-ts-mode tsx-ts-mode js-ts-mode)
              . (,islands-typescript-language-server "--stdio"))
             (rust-ts-mode . (,islands-rust-analyzer))
             ((c-ts-mode c++-ts-mode) . (,islands-clangd))
             (python-ts-mode . (,islands-basedpyright "--stdio"))
             (nix-ts-mode . (,islands-nixd))
             (json-ts-mode . (,islands-vscode-json-language-server "--stdio"))
             (toml-ts-mode . (,islands-taplo "lsp" "stdio"))
             (markdown-ts-mode . (,islands-marksman "server"))
             (bash-ts-mode . (,islands-bash-language-server "start"))))
    (add-to-list 'eglot-server-programs contact))

  (dolist (mode islands-eglot-modes)
    (add-hook (intern (format "%s-hook" mode)) #'islands-eglot-ensure))
  (add-hook 'rust-ts-mode-hook #'islands-rust-eglot-settings)
  (add-hook 'eglot-managed-mode-hook #'islands-enable-eglot-inlay-hints))

(use-package corfu
  :ensure t
  :custom
  (corfu-auto t)
  (corfu-auto-delay 0.1)
  (corfu-auto-prefix 1)
  (corfu-cycle t)
  :config
  (global-corfu-mode 1))

(use-package apheleia
  :ensure t
  :config
  (setf (alist-get 'islands-prettier apheleia-formatters)
        (list islands-prettier "--stdin-filepath" 'filepath)
        (alist-get 'islands-rustfmt apheleia-formatters)
        (list islands-rustfmt "--quiet" "--emit" "stdout")
        (alist-get 'islands-clang-format apheleia-formatters)
        (list islands-clang-format "-assume-filename"
              '(or (apheleia-formatters-local-buffer-file-name)
                   (apheleia-formatters-mode-extension)
                   ".c"))
        (alist-get 'islands-ruff apheleia-formatters)
        (list islands-ruff "format" "--silent" "--stdin-filename" 'filepath "-")
        (alist-get 'islands-nixfmt apheleia-formatters)
        (list islands-nixfmt)
        (alist-get 'islands-taplo apheleia-formatters)
        (list islands-taplo "format" "--colors" "never" "-")
        (alist-get 'islands-shfmt apheleia-formatters)
        (list islands-shfmt "-filename" 'filepath "-"))

  (dolist (mapping
           '((typescript-ts-mode . islands-prettier)
             (tsx-ts-mode . islands-prettier)
             (js-ts-mode . islands-prettier)
             (rust-ts-mode . islands-rustfmt)
             (c-ts-mode . islands-clang-format)
             (c++-ts-mode . islands-clang-format)
             (python-ts-mode . islands-ruff)
             (nix-ts-mode . islands-nixfmt)
             (json-ts-mode . islands-prettier)
             (toml-ts-mode . islands-taplo)
             (markdown-ts-mode . islands-prettier)
             (bash-ts-mode . islands-shfmt)))
    (setf (alist-get (car mapping) apheleia-mode-alist) (cdr mapping)))

  (apheleia-global-mode 1))

;;; init.el ends here
