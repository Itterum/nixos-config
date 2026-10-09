{ pkgs, ... }:

{
  home.packages = [ pkgs.caffeine-ng ];

  systemd.user.services.caffeine-ng = {
    Unit = {
      Description = "Caffeine NG idle inhibitor";
      PartOf = [ "graphical-session.target" ];
    };

    Service = {
      ExecStart = "${pkgs.caffeine-ng}/bin/caffeine";
      Restart = "on-failure";
    };

    Install.WantedBy = [ "graphical-session.target" ];
  };
}
