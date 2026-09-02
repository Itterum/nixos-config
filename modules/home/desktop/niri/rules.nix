{ ... }:

let
  # radius = {
  #   top-left = 10.0;
  #   top-right = 10.0;
  #   bottom-left = 10.0;
  #   bottom-right = 10.0;
  # };
in
{
  programs.niri.settings = {
    window-rules = [
      {
        # geometry-corner-radius = radius;
        clip-to-geometry = true;
        draw-border-with-background = false;
      }
      {
        matches = [ { app-id = "^org\\.wezfurlong\\.wezterm$"; } ];
        default-column-width = { };
      }
      {
        matches = [
          { app-id = "^gnome-control-center$"; }
          { app-id = "^pavucontrol$"; }
          { app-id = "^nm-connection-editor$"; }
        ];
        default-column-width.proportion = 0.5;
        open-floating = false;
      }
      {
        matches = [
          { app-id = "^org\\.gnome\\.Calculator$"; }
          { app-id = "^gnome-calculator$"; }
          { app-id = "^galculator$"; }
          { app-id = "^blueman-manager$"; }
          { app-id = "^org\\.gnome\\.Nautilus$"; }
          { app-id = "^xdg-desktop-portal$"; }
        ];
        open-floating = true;
      }
      {
        matches = [
          {
            app-id = "^steam$";
            title = "^notificationtoasts_\\d+_desktop$";
          }
        ];
        default-floating-position = {
          x = 10;
          y = 10;
          relative-to = "bottom-right";
        };
        open-focused = false;
      }
      {
        matches = [
          { app-id = "^org\\.wezfurlong\\.wezterm$"; }
          { app-id = "Alacritty"; }
          { app-id = "zen"; }
          { app-id = "com.mitchellh.ghostty"; }
          { app-id = "kitty"; }
        ];
        draw-border-with-background = false;
      }
      {
        matches = [
          {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          }
          { app-id = "zoom"; }
        ];
        open-floating = true;
      }
    ];

    layer-rules = [
      {
        matches = [ { namespace = "^launcher$"; } ];
        # geometry-corner-radius = radius;
        shadow = {
          enable = true;
          softness = 24;
          spread = 2;
          offset = {
            x = 0;
            y = 4;
          };
          color = "#00000070";
        };
      }
      {
        matches = [ { namespace = "^noctalia-wallpaper$"; } ];
        place-within-backdrop = true;
      }
    ];
  };
}
