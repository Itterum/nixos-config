{
  config,
  inputs,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  wallpaperPath = "${config.home.homeDirectory}/Pictures/Wallpapers/nix-wallpaper.png";
in
{
  imports = [
    inputs.noctalia.homeModules.default
  ];

  home.file."Pictures/Wallpapers/nix-wallpaper.png".source =
    ../../../assets/wallpapers/nix-wallpaper.png;

  programs.noctalia = {
    enable = true;
    systemd.enable = true;

    settings = {
      shell = {
        font_family = "FiraCode Nerd Font";
        settings_show_advanced = true;
      };

      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Noctalia";
      };

      wallpaper = {
        enabled = true;
        fill_mode = "crop";
        default.path = wallpaperPath;
      };

      notification.enable_daemon = true;
      lockscreen.enabled = true;

      idle.behavior = {
        lock = {
          timeout = 300;
          action = "lock";
          enabled = true;
        };
        screen-off = {
          timeout = 600;
          action = "screen_off";
          enabled = true;
        };
      }
      // lib.optionalAttrs osConfig.services.tlp.enable {
        suspend = {
          timeout = 1800;
          action = "command";
          command = "${pkgs.systemd}/bin/systemctl suspend";
          enabled = true;
        };
      };

      bar.main = {
        position = "top";
        thickness = 34;
        background_opacity = 1.0;
        radius = 12;
        margin_ends = 12;
        margin_edge = 8;
        reserve_space = true;
        start = [
          "launcher"
          "workspaces"
        ];
        center = [ "clock" ];
        end = [
          "media"
          "tray"
          "notifications"
          "clipboard"
          "network"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "control-center"
          "session"
        ];
      };
    };
  };
}
