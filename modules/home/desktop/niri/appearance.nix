{ ... }:

let
  palette = import ../palette.nix;
in
{
  programs.niri.settings = {
    layout = {
      gaps = 8;
      background-color = "transparent";
      center-focused-column = "never";
      preset-column-widths = [
        { proportion = 0.33333; }
        { proportion = 0.5; }
        { proportion = 0.66667; }
      ];
      default-column-width.proportion = 1.0;
      focus-ring = {
        width = 2;
        active.color = "#${palette.mauve}";
        inactive.color = "#${palette.overlay0}";
        urgent.color = "#${palette.red}";
      };
      border.enable = false;
      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
        color = "#00000070";
      };
    };

    overview.workspace-shadow.enable = false;
  };
}
