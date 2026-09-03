{ pkgs, ... }:

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
in
{
  programs.helix = {
    enable = true;
    defaultEditor = true;

    themes.transparent_theme = {
      inherits = "jetbrains_dark";
      "ui.background" = { };
    };

    extraPackages = with pkgs; [
      bash-language-server
      basedpyright
      csharp-ls
      csharpier
      kdlfmt
      marksman
      nixd
      nixfmt
      prettier
      qt6.qtdeclarative
      ruff
      rust-analyzer
      taplo
      typescript
      typescript-language-server
      vscode-langservers-extracted
    ];

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

        basedpyright = {
          command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
          args = [ "--stdio" ];
        };

        ruff = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [ "server" ];
        };

        csharp-ls.command = "${pkgs.csharp-ls}/bin/csharp-ls";
        qmlls.command = "${pkgs.qt6.qtdeclarative}/bin/qmlls";

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
            name = "c-sharp";
            roots = [
              "*.sln"
              "*.slnx"
              "*.csproj"
            ];
            language-servers = [ "csharp-ls" ];
            formatter = {
              command = "${pkgs.csharpier}/bin/dotnet-csharpier";
              args = [
                "format"
                "--write-stdout"
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
            name = "qml";
            language-servers = [ "qmlls" ];
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
  };
}
