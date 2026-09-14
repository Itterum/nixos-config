{ config, pkgs, ... }:

{
  services.greetd = {
    enable = true;
    settings.default_session = {
      user = "greeter";
      # Matches the Exec command shipped by hyprland-uwsm.desktop.
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session --cmd '${pkgs.uwsm}/bin/uwsm start -e -D Hyprland hyprland.desktop'";
    };
  };
}
