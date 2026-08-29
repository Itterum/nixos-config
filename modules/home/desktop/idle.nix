{
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  lockCommand = "${pkgs.gtklock}/bin/gtklock --daemonize";
in
{
  home.packages = with pkgs; [
    brightnessctl
    playerctl
  ];

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
