{ config, pkgs, ... }:

let
  emacsLanguageConfig = pkgs.replaceVars ./emacs/languages.el {
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
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";
  home.stateVersion = "26.05";
  home.sessionVariables = {
    COLORTERM = "truecolor";
    EDITOR = "emacs";
    VISUAL = "emacs";
  };

  home.packages = with pkgs; [
    btop
    ripgrep
    fd
    tree
    jq

    fastfetch
    devenv
    uv
    rustup

    kubectl
    k9s
    teleport

    bubblewrap
    codex
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "lyashenko.ivan";
      user.email = "ivan.lyashenko.it@gmail.com";
      init.defaultBranch = "main";
    };
  };
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.home-manager.enable = true;
  programs.bash.enable = true;
  programs.zellij = {
    enable = true;
    settings = {
      default_mode = "locked";
      default_layout = "default";
      pane_frames = false;
    };
    layouts.default = ''
      layout {
          default_tab_template {
              children
              pane size=1 borderless=true {
                  plugin location="file:${config.xdg.configHome}/zellij/plugins/zjstatus.wasm" {
                      format_left   "{mode}"
                      format_center "{tabs}"
                      format_right  "#[fg=#808080] {session} "
                      format_space  ""

                      border_enabled "false"

                      mode_normal          "#[fg=#A9B7C6,bold] {name} "
                      mode_locked          "#[fg=#CC7832,bold] {name} "
                      mode_default_to_mode "normal"

                      tab_normal "#[fg=#808080] {index}:{name} "
                      tab_active "#[fg=#A9B7C6,bold] {index}:{name} "
                  }
              }
          }
      }
    '';
  };

  xdg.configFile."zellij/plugins/zjstatus.wasm".source = pkgs.zellijPlugins.zjstatus;
  xdg.configFile."emacs/themes/islands-dark-transparent-theme.el".source =
    ./emacs/islands-dark-transparent-theme.el;
  xdg.configFile."emacs/files.el".source = ./emacs/files.el;
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
      (epkgs.treesit-grammars.with-grammars (grammars: with grammars; [
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
      ]))
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
