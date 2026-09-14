{ inputs, lib, pkgs, ... }:

let
  shellPackage = inputs.itterum-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  defaultConfig = builtins.fromJSON (
    builtins.readFile "${inputs.itterum-shell}/config/itterum-shell/shell.json"
  );
  shellConfig = defaultConfig // {
    applications = defaultConfig.applications or [ ];
  };
in
{
  home.packages = [ shellPackage ];

  xdg.configFile."itterum-shell/shell.json" = {
    force = true;
    text = builtins.toJSON shellConfig;
  };

  systemd.user.services.itterum-shell = {
    Unit = {
      Description = "Itterum desktop shell";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
      StartLimitBurst = 5;
      StartLimitIntervalSec = 60;
    };
    Service = {
      ExecStart = lib.getExe shellPackage;
      Restart = "on-failure";
      RestartSec = "3s";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
