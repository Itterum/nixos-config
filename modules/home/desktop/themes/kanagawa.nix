{ lib, ... }:

let
  palette = {
    background = "#1f1f28";
    foreground = "#dcd7ba";
    accent = "#7e9cd8";
    muted = "#727169";
    selection = "#2d4f67";
    red = "#e46876";
    green = "#98bb6c";
    yellow = "#e6c384";
    blue = "#7e9cd8";
    magenta = "#957fb8";
    cyan = "#7fb4ca";
  };
in
{
  options.itterum.theme = {
    name = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = "kanagawa";
    };
    colorScheme = lib.mkOption {
      type = lib.types.enum [ "dark" ];
      readOnly = true;
      default = "dark";
    };
    palette = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      readOnly = true;
      default = palette;
    };
  };
}
