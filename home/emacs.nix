{ config, pkgs, ... }:

let
  emacsLanguageConfig = pkgs.replaceVars ../emacs/languages.el {
    typescriptLanguageServer = "${pkgs.typescript-language-server}/bin/typescript-language-server";
    rustAnalyzer = "${pkgs.rust-analyzer}/bin/rust-analyzer";
    clangd = "${pkgs.clang-tools}/bin/clangd";
    basedpyright = "${pkgs.basedpyright}/bin/basedpyright-langserver";
    nixd = "${pkgs.nixd}/bin/nixd";
    vscodeJsonLanguageServer = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
    taplo = "${pkgs.taplo}/bin/taplo";
    marksman = "${pkgs.marksman}/bin/marksman";
    bashLanguageServer = "${pkgs.bash-language-server}/bin/bash-language-server";

    prettier = "${pkgs.prettier}/bin/prettier";
    rustfmt = "${pkgs.rustfmt}/bin/rustfmt";
    clangFormat = "${pkgs.clang-tools}/bin/clang-format";
    ruff = "${pkgs.ruff}/bin/ruff";
    nixfmt = "${pkgs.nixfmt}/bin/nixfmt";
    shfmt = "${pkgs.shfmt}/bin/shfmt";
  };
in

{
  xdg.configFile."emacs/themes/islands-dark-transparent-theme.el".source =
    ../emacs/islands-dark-transparent-theme.el;
  xdg.configFile."emacs/files.el".source = ../emacs/files.el;
  xdg.configFile."emacs/languages.el".source = emacsLanguageConfig;

  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
    extraPackages = epkgs: [
      epkgs.nix-mode
      epkgs.which-key
      epkgs.corfu
      epkgs.apheleia
      epkgs.nix-ts-mode
      epkgs.markdown-ts-mode
      (epkgs.treesit-grammars.with-grammars (
        grammars: with grammars; [
          tree-sitter-bash
          tree-sitter-c
          tree-sitter-cpp
          tree-sitter-javascript
          tree-sitter-json
          tree-sitter-markdown
          tree-sitter-nix
          tree-sitter-python
          tree-sitter-rust
          tree-sitter-toml
          tree-sitter-tsx
          tree-sitter-typescript
        ]
      ))
    ];
    extraConfig = ''
      (add-to-list 'custom-theme-load-path "${config.xdg.configHome}/emacs/themes")
      (mapc #'disable-theme custom-enabled-themes)
      (load-theme 'islands-dark-transparent t)

      (load "${config.xdg.configHome}/emacs/files.el" nil nil)
      (load "${config.xdg.configHome}/emacs/languages.el" nil nil)

      (require 'which-key)
      (which-key-mode 1)

      (setq which-key-idle-delay 0.1)
    '';
  };
}
