{ ... }:

let
  palette = import ../../home/desktop/palette.nix;
  wallpaper = ../../../assets/wallpapers/nix-wallpaper.png;
in
{
  programs.gtklock = {
    enable = true;

    config.main = {
      gtk-theme = "Adwaita-dark";
      time-format = "%H:%M";
      date-format = "%A, %d %B";
    };

    style = ''
      window {
        background-image: url("file://${wallpaper}");
        background-size: cover;
        background-position: center;
        color: #${palette.text};
      }

      entry {
        background-color: rgba(49, 50, 68, 0.92);
        border: 2px solid #${palette.mauve};
        border-radius: 10px;
        color: #${palette.text};
      }
    '';
  };
}
