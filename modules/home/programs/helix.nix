{ pkgs, ... }:

{
  programs.helix = {
    enable = true;
    defaultEditor = true;

    # ~/.config/helix/config.toml
    settings = {
      theme = "catppuccin_mocha_transparent";

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

        soft-wrap = {
          enable = true;
        };

        lsp = {
          auto-signature-help = true;
          display-inlay-hints = true;
          display-color-swatches = true;
          snippets = true;
        };

        inline-diagnostics = {
          cursor-line = "warning";
        };

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

          center = [
            "file-name"
          ];

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

        insert = {
          "C-s" = [
            "normal_mode"
            ":write"
            "insert_mode"
          ];
        };
      };
    };

    # ~/.config/helix/languages.toml
    languages = {
      language-server = {
        # TypeScript / JavaScript
        typescript-language-server = {
          command = "${pkgs.typescript-language-server}/bin/typescript-language-server";

          args = [
            "--stdio"
            "--tsserver-path=${pkgs.typescript}/lib/node_modules/typescript/lib"
          ];
        };

        # Rust
        rust-analyzer = {
          command = "${pkgs.rust-analyzer}/bin/rust-analyzer";

          config = {
            check = {
              command = "clippy";
              allTargets = true;
            };

            cargo = {
              buildScripts = {
                enable = true;
              };
            };

            procMacro = {
              enable = true;
            };

            completion = {
              fullFunctionSignatures = {
                enable = true;
              };
            };

            imports = {
              granularity = {
                group = "module";
              };
            };

            inlayHints = {
              bindingModeHints = {
                enable = true;
              };

              closureReturnTypeHints = {
                enable = "with_block";
              };

              lifetimeElisionHints = {
                enable = "skip_trivial";
                useParameterNames = true;
              };
            };
          };
        };

        # Python
        basedpyright = {
          command = "${pkgs.basedpyright}/bin/basedpyright-langserver";

          args = [ "--stdio" ];
        };

        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
        };

        # C#
        csharp-ls = {
          command = "${pkgs.csharp-ls}/bin/csharp-ls";
        };

        # QML / Quickshell
        qmlls = {
          command = "${pkgs.qt6.qtdeclarative}/bin/qmlls";
        };

        # JSON
        vscode-json-language-server = {
          command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
          args = [ "--stdio" ];
        };

        # TOML
        taplo = {
          command = "${pkgs.taplo}/bin/taplo";
          args = [
            "lsp"
            "stdio"
          ];
        };

        # Markdown
        marksman = {
          command = "${pkgs.marksman}/bin/marksman";
          args = [ "server" ];
        };

        # Bash
        bash-language-server = {
          command = "${pkgs.bash-language-server}/bin/bash-language-server";
          args = [ "start" ];
        };

        # Nix
        nixd = {
          command = "${pkgs.nixd}/bin/nixd";
        };
      };

      language = [
        # JavaScript / TypeScript
        {
          name = "typescript";
          language-servers = [ "typescript-language-server" ];

          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = [
              "--stdin-filepath"
              "%{buffer_name}"
            ];
          };

          auto-format = true;
        }

        {
          name = "tsx";
          language-servers = [ "typescript-language-server" ];

          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = [
              "--stdin-filepath"
              "%{buffer_name}"
            ];
          };

          auto-format = true;
        }

        {
          name = "javascript";
          language-servers = [ "typescript-language-server" ];

          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = [
              "--stdin-filepath"
              "%{buffer_name}"
            ];
          };

          auto-format = true;
        }

        {
          name = "jsx";
          language-servers = [ "typescript-language-server" ];

          formatter = {
            command = "${pkgs.prettier}/bin/prettier";
            args = [
              "--stdin-filepath"
              "%{buffer_name}"
            ];
          };

          auto-format = true;
        }

        # Rust
        {
          name = "rust";

          roots = [
            "Cargo.toml"
            "Cargo.lock"
          ];

          language-servers = [ "rust-analyzer" ];
          auto-format = true;
        }

        # Python
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

        # C#
        {
          name = "c-sharp";

          roots = [
            "*.sln"
            "*.slnx"
            "*.csproj"
          ];

          language-servers = [ "csharp-ls" ];

          formatter = {
            # В nixpkgs пакет называется csharpier,
            # но binary — dotnet-csharpier
            command = "${pkgs.csharpier}/bin/dotnet-csharpier";

            args = [
              "format"
              "--write-stdout"
            ];
          };

          auto-format = true;
        }

        # Nix
        {
          name = "nix";
          language-servers = [ "nixd" ];

          formatter = {
            command = "${pkgs.nixfmt}/bin/nixfmt";
          };

          auto-format = true;
        }

        # QML / Quickshell
        {
          name = "qml";
          language-servers = [ "qmlls" ];
        }

        # JSON
        {
          name = "json";
          language-servers = [ "vscode-json-language-server" ];
        }

        # TOML
        {
          name = "toml";
          language-servers = [ "taplo" ];
        }

        # Markdown
        {
          name = "markdown";
          language-servers = [ "marksman" ];
        }

        # Bash
        {
          name = "bash";
          language-servers = [ "bash-language-server" ];
        }

        # KDL has no LSP in nixpkgs, but Helix supports formatting it.
        {
          name = "kdl";
          formatter = {
            command = "${pkgs.kdlfmt}/bin/kdlfmt";
            args = [
              "format"
              "-"
            ];
          };
          auto-format = true;
        }
      ];
    };

    # ~/.config/helix/themes/catppuccin_mocha_transparent.toml
    themes = {
      catppuccin_mocha_transparent = {
        inherits = "catppuccin_mocha";
        "ui.background" = { };
      };
    };

    # Инструменты, которые Helix может использовать
    extraPackages = with pkgs; [
      # JS / TS
      typescript
      typescript-language-server
      prettier

      # Rust
      rust-analyzer

      # Python
      basedpyright
      ruff

      # C#
      csharp-ls
      csharpier

      # Nix
      nixd
      nixfmt

      # QML / Quickshell
      qt6.qtdeclarative

      # JSON / TOML / Markdown / Bash
      vscode-langservers-extracted
      taplo
      marksman
      bash-language-server

      # KDL
      kdlfmt
    ];
  };
}
