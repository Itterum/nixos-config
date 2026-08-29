{ ... }:

let
  palette = import ./palette.nix;
in
{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "FiraCode Nerd Font:size=14";
        terminal = "ghostty";
        layer = "overlay";
        prompt = ":  ";
        icon-theme = "Papirus-Dark";
        icons-enabled = true;
        width = 42;
        lines = 12;
        horizontal-pad = 20;
        vertical-pad = 14;
        inner-pad = 8;
      };

      colors = {
        background = "${palette.base}f2";
        text = "${palette.text}ff";
        prompt = "${palette.mauve}ff";
        placeholder = "${palette.overlay0}ff";
        input = "${palette.text}ff";
        match = "${palette.mauve}ff";
        selection = "${palette.surface0}ff";
        selection-text = "${palette.text}ff";
        selection-match = "${palette.mauve}ff";
        counter = "${palette.subtext0}ff";
        border = "${palette.mauve}ff";
      };

      border = {
        width = 2;
        radius = 0;
      };
    };
  };
}
