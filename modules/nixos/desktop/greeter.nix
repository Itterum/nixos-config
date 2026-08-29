{
  config,
  pkgs,
  ...
}:

let
  palette = import ../../home/desktop/palette.nix;
  wallpaper = ../../../assets/wallpapers/nix-wallpaper.png;
  style = pkgs.writeText "gtkgreet.css" ''
    window {
      background-image: url("file://${wallpaper}");
      background-size: cover;
      background-position: center;
      color: #${palette.text};
    }

    box#body {
      background-color: rgba(30, 30, 46, 0.92);
      border: 2px solid #${palette.mauve};
      border-radius: 12px;
      padding: 48px;
    }

    entry {
      background-color: #${palette.surface0};
      color: #${palette.text};
    }

    button {
      background: #${palette.mauve};
      color: #${palette.crust};
    }
  '';
in
{
  services.displayManager.autoLogin.enable = false;

  services.greetd = {
    enable = true;
    useTextGreeter = false;

    settings.default_session.command = "${pkgs.cage}/bin/cage -s -m extend -- ${pkgs.gtkgreet}/bin/gtkgreet -l -c ${config.programs.niri.package}/bin/niri-session -s ${style}";
  };
}
