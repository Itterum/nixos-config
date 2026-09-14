{ config, pkgs, ... }:

let
  wallpaper = "${config.home.homeDirectory}/Pictures/Wallpapers/nix-wallpaper.png";
  lock = "${pkgs.swaylock}/bin/swaylock -f";
in
{
  home.file."Pictures/Wallpapers/nix-wallpaper.png".source =
    ../../../assets/wallpapers/nix-wallpaper.png;

  programs = {
    fuzzel.enable = true;
    swaylock.enable = true;
    waybar = {
      enable = true;
      systemd.enable = true;
    };
  };

  services = {
    mako.enable = true;
    swayidle = {
      enable = true;
      events.before-sleep = lock;
      timeouts = [
        {
          timeout = 300;
          command = lock;
        }
        {
          timeout = 600;
          command = "${config.programs.niri.package}/bin/niri msg action power-off-monitors";
        }
      ];
    };
  };

  systemd.user.services.swaybg = {
    Unit = {
      Description = "Desktop wallpaper";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${wallpaper} -m fill";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
