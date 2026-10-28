{ config, pkgs, ... }:

let
  webLanguage = name: {
    inherit name;
    language-servers = [ "typescript-language-server" ];
    formatter = {
      command = "${pkgs.prettier}/bin/prettier";
      args = [
        "--stdin-filepath"
        "%{buffer_name}"
      ];
    };
    auto-format = true;
  };

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
  home.sessionVariables.COLORTERM = "truecolor";

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

  programs.helix = {
    enable = true;
    defaultEditor = true;

    themes.transparent_theme = {
      inherits = "jetbrains_dark";
      "ui.background" = { };
    };

    settings = {
      theme = "transparent_theme";

      editor = {
        line-number = "relative";
        cursorline = true;
        color-modes = true;
        bufferline = "multiple";
        auto-format = true;
        auto-completion = true;
        completion-trigger-len = 1;
        end-of-line-diagnostics = "hint";
        rulers = [ 100 ];

        soft-wrap.enable = true;

        lsp = {
          auto-signature-help = true;
          display-inlay-hints = true;
          display-color-swatches = true;
          snippets = true;
        };

        inline-diagnostics.cursor-line = "warning";

        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };

        statusline = {
          left = [
            "mode"
            "spinner"
            "version-control"
          ];
          center = [ "file-name" ];
          right = [
            "diagnostics"
            "selections"
            "position"
            "file-encoding"
            "file-line-ending"
            "file-type"
          ];
          separator = "|";
          mode = {
            normal = "NORMAL";
            insert = "INSERT";
            select = "SELECT";
          };
          diagnostics = [
            "warning"
            "error"
          ];
          workspace-diagnostics = [
            "warning"
            "error"
          ];
        };

        file-picker = {
          hidden = false;
          git-ignore = true;
        };
      };

      keys = {
        normal = {
          "C-s" = ":write";
          "C-q" = ":quit";
        };
        insert."C-s" = [
          "normal_mode"
          ":write"
          "insert_mode"
        ];
      };
    };

    languages = {
      language-server = {
        typescript-language-server = {
          command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
          args = [
            "--stdio"
            "--tsserver-path=${pkgs.typescript}/lib/node_modules/typescript/lib"
          ];
        };

        rust-analyzer = {
          command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
          config = {
            check = {
              command = "clippy";
              allTargets = true;
            };
            cargo.buildScripts.enable = true;
            procMacro.enable = true;
            completion.fullFunctionSignatures.enable = true;
            imports.granularity.group = "module";
            inlayHints = {
              bindingModeHints.enable = true;
              closureReturnTypeHints.enable = "with_block";
              lifetimeElisionHints = {
                enable = "skip_trivial";
                useParameterNames = true;
              };
            };
          };
        };

        clangd.command = "${pkgs.clang-tools}/bin/clangd";

        basedpyright = {
          command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
          args = [ "--stdio" ];
        };
        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
        };
        vscode-json-language-server = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
          args = [ "--stdio" ];
        };
        taplo = {
          command = "${pkgs.taplo}/bin/taplo";
          args = [
            "lsp"
            "stdio"
          ];
        };
        marksman = {
          command = "${pkgs.marksman}/bin/marksman";
          args = [ "server" ];
        };
        bash-language-server = {
          command = "${pkgs.bash-language-server}/bin/bash-language-server";
          args = [ "start" ];
        };
        nixd.command = "${pkgs.nixd}/bin/nixd";
      };

      language =
        map webLanguage [
          "typescript"
          "tsx"
          "javascript"
          "jsx"
        ]
        ++ [
          {
            name = "rust";
            roots = [
              "Cargo.toml"
              "Cargo.lock"
            ];
            language-servers = [ "rust-analyzer" ];
            auto-format = true;
          }
          {
            name = "c";
            language-servers = [ "clangd" ];
            formatter.command = "${pkgs.clang-tools}/bin/clang-format";
            auto-format = true;
          }
          {
            name = "cpp";
            language-servers = [ "clangd" ];
            formatter.command = "${pkgs.clang-tools}/bin/clang-format";
            auto-format = true;
          }
          {
            name = "python";
            roots = [
              "pyproject.toml"
              "uv.lock"
              "requirements.txt"
              ".git"
            ];
            language-servers = [
              "basedpyright"
              {
                name = "ruff";
                only-features = [
                  "diagnostics"
                  "code-action"
                ];
              }
            ];
            formatter = {
              command = "${pkgs.ruff}/bin/ruff";
              args = [
                "format"
                "-"
              ];
            };
            auto-format = true;
          }
          {
            name = "nix";
            language-servers = [ "nixd" ];
            formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
            auto-format = true;
          }
          {
            name = "json";
            language-servers = [ "vscode-json-language-server" ];
          }
          {
            name = "toml";
            language-servers = [ "taplo" ];
          }
          {
            name = "markdown";
            language-servers = [ "marksman" ];
          }
          {
            name = "bash";
            language-servers = [ "bash-language-server" ];
          }
        ];
    };

    extraPackages = with pkgs; [
      typescript
      typescript-language-server
      prettier
      rust-analyzer
      clang-tools
      basedpyright
      ruff
      nixd
      nixfmt
      vscode-langservers-extracted
      taplo
      marksman
      bash-language-server
    ];
  };
}
