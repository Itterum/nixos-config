{ config, pkgs, ... }:

let
  emacsInit = pkgs.replaceVars ../emacs/init.el {
    emacsConfigDirectory = "${config.xdg.configHome}/emacs";

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

  emacsPackage = pkgs.emacsWithPackagesFromUsePackage {
    config = emacsInit;
    package = pkgs.emacs-nox;
    extraEmacsPackages = epkgs: [
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
  };
in

{
  xdg.configFile."emacs/themes/islands-dark-transparent-theme.el".source =
    ../emacs/islands-dark-transparent-theme.el;

  home.file.".emacs.d/init.el".source = emacsInit;
  home.packages = [ emacsPackage ];
}
