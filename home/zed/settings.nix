{
  programs.zed-editor.userSettings = {
    window_decorations = "server";
    title_bar = {
      show_sign_in = false;
      show_menus = false;
      button_layout = "platform_default";
    };
    disable_ai = false;
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
    languages.Nix.language_servers = [ "nixd" ];
    ui_font_family = ".ZedSans";
    ui_font_size = 15.0;
    buffer_font_family = ".ZedMono";
    buffer_font_size = 13.0;
    helix_mode = true;
    vim_mode = false;
    base_keymap = "JetBrains";
    theme = {
      mode = "system";
      dark = "Kanagawa";
      light = "Kanagawa";
    };
    terminal = {
      shell = "system";
      font_family = ".ZedMono";
      dock = "right";
    };
    session.trust_all_worktrees = true;
  };
}
