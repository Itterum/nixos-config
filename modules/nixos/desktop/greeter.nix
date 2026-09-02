{
  inputs,
  pkgs,
  ...
}:

{
  imports = [
    inputs.noctalia-greeter.nixosModules.default
  ];

  programs.noctalia-greeter = {
    enable = true;
    settings = {
      session.default = "niri";
      idle.timeout = 300;
      cursor = {
        theme = "macOS";
        size = 24;
        path = "${pkgs.apple-cursor}/share/icons";
      };
      keyboard = {
        layout = "us,ru";
        options = "ctrl:nocaps,grp:shifts_toggle";
      };
    };
  };

  services.greetd = {
    useTextGreeter = false;
    settings.default_session.command = "/run/current-system/sw/bin/noctalia-greeter-session";
    settings.default_session.user = "greeter";
  };
}
