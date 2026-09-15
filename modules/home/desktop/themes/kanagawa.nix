{ lib, ... }:

let
  palette = {
    background = "#1f1f28";
    foreground = "#dcd7ba";
    accent = "#dcd7ba";
    muted = "#54546D";
    selection = "#363646";
    red = "#c34043";
    green = "#76946a";
    yellow = "#c0a36e";
    blue = "#7e9cd8";
    magenta = "#957fb8";
    cyan = "#6a9589";
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
