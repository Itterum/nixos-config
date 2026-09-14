{
  programs.helix.settings = {
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
}
