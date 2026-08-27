{ pkgs, ... }:

{
  programs.zed-editor = {
    enable = true;

    mutableUserSettings = false;
    mutableUserKeymaps = false;
    mutableUserDebug = false;

    extensions = [
      "nix"
      "toml"
      "qml"
    ];
    extraPackages = [ pkgs.nixd ];

    themes = {
      catppuccin-system = ./zed/themes/catppuccin-system.json;
      noctalia = ./zed/themes/noctalia.json;
    };

    userSettings = {
      window_decorations = "server";
      title_bar = {
        show_sign_in = false;
        show_menus = false;
        button_layout = "platform_default";
      };
      disable_ai = true;
      edit_predictions.allow_data_collection = "no";
      soft_wrap = "editor_width";
      relative_line_numbers = "enabled";
      cli_default_open_behavior = "new_window";
      format_on_save = "on";
      code_lens = "on";
      inlay_hints = {
        enabled = true;
        show_type_hints = true;
      };
      diagnostics = {
        include_warnings = true;
        inline.enabled = true;
      };
      ui_font_family = ".ZedSans";
      ui_font_size = 15.0;
      buffer_font_family = "FiraCode Nerd Font";
      buffer_font_size = 14.0;
      helix_mode = true;
      vim_mode = false;
      base_keymap = "JetBrains";
      theme = {
        mode = "system";
        dark = "Catppuccin Mocha Default Background";
        light = "Catppuccin Mocha Default Background";
      };
      terminal = {
        shell = "system";
        font_family = "FiraCode Nerd Font Mono";
        dock = "right";
      };
      session.trust_all_worktrees = true;
    };

    userKeymaps = [
      {
        "context" = "!ProjectPanel";
        "bindings" = {
          "alt-e" = "project_panel::ToggleFocus";
        };
      }
      {
        "context" = "Workspace";
        "bindings" = {
          "alt-l" = "workspace::ToggleLeftDock";
          "alt-r" = "workspace::ToggleRightDock";
          "alt-b" = "workspace::ToggleBottomDock";
          "alt-g" = "git_panel::ToggleFocus";
          "alt-d" = "debug_panel::ToggleFocus";
          "alt-o" = "projects::OpenRecent";
        };
      }
      {
        "context" = "!Editor";
        "bindings" = {
          "alt-e" = "editor::ToggleFocus";
        };
      }
      {
        "context" = "Workspace";
        "bindings" = {
          "shift shift" = "file_finder::Toggle";
        };
      }
    ];
  };
}
