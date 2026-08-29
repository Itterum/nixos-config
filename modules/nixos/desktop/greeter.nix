{
  config,
  pkgs,
  ...
}:

let
  niriSession = "${config.programs.niri.package}/bin/niri-session";
in
{
  services.greetd = {
    enable = true;
    useTextGreeter = true;

    settings = {
      initial_session = {
        command = niriSession;
        user = "itterum";
      };

      default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --asterisks --cmd ${niriSession}";
    };
  };
}
