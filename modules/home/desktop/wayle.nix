{ config, ... }:

let
  palette = import ./palette.nix;
  wallpaperPath = "${config.home.homeDirectory}/Pictures/Wallpapers/nix-wallpaper.png";
in
{
  home.file."Pictures/Wallpapers/nix-wallpaper.png".source =
    ../../../assets/wallpapers/nix-wallpaper.png;

  services.wayle = {
    enable = true;
    autoInstallDependencies = true;
    settings = {
      bar = {
        button-bg-opacity = 0;
        button-variant = "basic";
        layout = [
          {
            center = [ ];
            left = [
              "niri-workspaces"
              "window-title"
            ];
            monitor = "*";
            right = [
              "systray"
              "idle-inhibit"
              "battery"
              "bluetooth"
              "network"
              "microphone"
              "volume"
              "keyboard-input"
              "clock"
              "notifications"
            ];
            show = true;
          }
        ];
        scale = 0.7;
      };
      modules = {
        bluetooth.label-show = false;
        clock = {
          icon-show = false;
          dropdown-show-seconds = true;
          format = "%a %b %d %H:%M:%S";
        };
        keyboard-input.icon-show = false;
        network.label-show = false;
        volume.label-show = false;
      };
      styling = {
        scale = 1;
        palette = {
          bg = "#${palette.crust}";
          elevated = "#${palette.base}";
          fg = "#${palette.text}";
          fg-muted = "#${palette.subtext0}";
          primary = "#${palette.mauve}";
          surface = "#${palette.mantle}";
          blue = "#${palette.blue}";
          green = "#${palette.green}";
          red = "#${palette.red}";
          yellow = "#${palette.yellow}";
        };
      };
      wallpaper = {
        engine-enabled = true;
        cycling-enabled = false;
        monitors = [
          {
            name = "eDP-1";
            wallpaper = wallpaperPath;
            fit-mode = "fill";
          }
        ];
      };
    };
  };
}
