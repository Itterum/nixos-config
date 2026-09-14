{ ... }:

{
  programs.zed-editor = {
    enable = true;
    userSettings = {
      theme = {
        mode = "dark";
        dark = "Kanagawa";
        light = "Kanagawa";
      };
      ui_font_size = 15;
      buffer_font_size = 14;
      terminal.shell.program = "zsh";
    };
  };
}
