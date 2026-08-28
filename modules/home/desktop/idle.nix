{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  palette = import ./palette.nix;
  lockCommand = "${pkgs.swaylock}/bin/swaylock -f";
in
{
  home.packages = with pkgs; [
    brightnessctl
    playerctl
  ];

  programs.swaylock = {
    enable = true;
    settings = {
      color = palette.base;
      font = "FiraCode Nerd Font";
      font-size = 24;
      indicator-radius = 100;
      indicator-thickness = 8;
      inside-color = "${palette.base}cc";
      inside-clear-color = "${palette.yellow}cc";
      inside-ver-color = "${palette.blue}cc";
      inside-wrong-color = "${palette.red}cc";
      ring-color = palette.surface1;
      ring-clear-color = palette.yellow;
      ring-ver-color = palette.blue;
      ring-wrong-color = palette.red;
      key-hl-color = palette.mauve;
      bs-hl-color = palette.red;
      text-color = palette.text;
      text-clear-color = palette.base;
      text-ver-color = palette.base;
      text-wrong-color = palette.base;
      separator-color = "00000000";
      ignore-empty-password = true;
      show-failed-attempts = true;
    };
  };

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = lockCommand;
      lock = lockCommand;
    };
    timeouts = [
      {
        timeout = 300;
        command = lockCommand;
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ]
    ++ lib.optionals osConfig.services.tlp.enable [
      {
        timeout = 1800;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };
}
