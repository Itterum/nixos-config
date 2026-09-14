{ config, lib, ... }:

let
  palette = config.itterum.theme.palette;
  rgb = color: "rgb(${lib.removePrefix "#" color})";
in
{
  imports = [ ./binds.nix ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = null;
    portalPackage = null;
    systemd.enable = false;

    settings = {
      "$mod" = "SUPER";
      monitor = [ ",preferred,auto,1" ];

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
        "col.active_border" = rgb palette.accent;
        "col.inactive_border" = rgb palette.muted;
      };

      decoration.rounding = 8;
      input = {
        kb_layout = "us";
        follow_mouse = 1;
      };
    };
  };
}
