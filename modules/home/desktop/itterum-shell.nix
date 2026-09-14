{ config, inputs, lib, pkgs, ... }:

let
  shellPackage = inputs.itterum-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
  defaultConfig = builtins.fromJSON (
    builtins.readFile "${inputs.itterum-shell}/config/itterum-shell/shell.json"
  );
  defaultDockConfig = builtins.readFile (
    "${inputs.itterum-shell}/config/itterum-shell/arc-dock.json"
  );
  shellConfig = defaultConfig // {
    applications = config.itterum.applications.desktopIds;
  };
  palette = config.itterum.theme.palette;
in
{
  home.packages = [ shellPackage ];

  xdg.configFile."itterum-shell/shell.json" = {
    force = true;
    text = builtins.toJSON shellConfig;
  };

  xdg.configFile."itterum-shell/arc-dock.json" = {
    force = true;
    text = defaultDockConfig;
  };

  xdg.configFile."itterum-shell/theme/colors.toml".text = ''
    background = "${palette.background}"
    foreground = "${palette.foreground}"
    accent = "${palette.accent}"
    muted = "${palette.muted}"
    red = "${palette.red}"
    color0 = "${palette.background}"
    color1 = "${palette.red}"
    color2 = "${palette.green}"
    color3 = "${palette.yellow}"
    color4 = "${palette.blue}"
    color5 = "${palette.magenta}"
    color6 = "${palette.cyan}"
    color7 = "${palette.foreground}"
    color8 = "${palette.muted}"
  '';

  xdg.configFile."itterum-shell/theme/shell.toml".text = ''
    [bar]
    background = "background"
    text = "foreground"
    active = "accent"

    [popups]
    background = "background"
    text = "foreground"
    border = "accent"

    [menu]
    background = "background"
    text = "foreground"
    border = "muted"
    selected-background = "${palette.selection}"
    selected-text = "foreground"
  '';

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
