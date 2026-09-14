{ config, ... }:

let
  palette = config.itterum.theme.palette;
  rgb = value:
    let
      hex = builtins.substring 1 6 value;
      fromHex = pair: builtins.fromTOML "value = 0x${pair}";
    in
    [
      (fromHex (builtins.substring 0 2 hex)).value
      (fromHex (builtins.substring 2 2 hex)).value
      (fromHex (builtins.substring 4 2 hex)).value
    ];
in
{
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;
    settings = {
      default_shell = "zsh";
      theme = "kanagawa";
      pane_frames = false;
      themes.kanagawa = {
        fg = rgb palette.foreground;
        bg = rgb palette.background;
        black = rgb palette.background;
        red = rgb palette.red;
        green = rgb palette.green;
        yellow = rgb palette.yellow;
        blue = rgb palette.blue;
        magenta = rgb palette.magenta;
        cyan = rgb palette.cyan;
        white = rgb palette.foreground;
        orange = rgb palette.yellow;
      };
    };
  };
}
