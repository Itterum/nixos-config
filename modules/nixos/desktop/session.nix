{
  config,
  pkgs,
  ...
}:

{
  services.displayManager = {
    defaultSession = "niri";
    autoLogin.enable = false;
  };

  services.greetd = {
    enable = true;
    useTextGreeter = true;

    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd ${config.programs.niri.package}/bin/niri-session";
  };
}
