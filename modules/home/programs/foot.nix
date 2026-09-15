{ config, lib, ... }:

let
  palette = config.itterum.theme.palette;
  hex = lib.removePrefix "#";
in
{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "FiraCode Nerd Font:size=11";
        pad = "10x10";
      };
      colors-dark = {
        background = hex palette.background;
        foreground = hex palette.foreground;
        regular0 = hex palette.background;
        regular1 = hex palette.red;
        regular2 = hex palette.green;
        regular3 = hex palette.yellow;
        regular4 = hex palette.blue;
        regular5 = hex palette.magenta;
        regular6 = hex palette.cyan;
        regular7 = hex palette.foreground;
        bright0 = hex palette.muted;
        bright1 = hex palette.red;
        bright2 = hex palette.green;
        bright3 = hex palette.yellow;
        bright4 = hex palette.blue;
        bright5 = hex palette.magenta;
        bright6 = hex palette.cyan;
        bright7 = hex palette.foreground;
        selection-background = hex palette.selection;
        selection-foreground = hex palette.foreground;
      };
    };
  };
}
