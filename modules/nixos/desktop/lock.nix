{ ... }:

let
  palette = import ../../home/desktop/palette.nix;
  wallpaper = ../../../assets/wallpapers/nix-wallpaper.png;
in
{
  programs.gtklock = {
    enable = true;

    config.main = {
      gtk-theme = "adw-gtk3-dark";
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
        background-color: rgba(54, 54, 58, 0.92);
        border: 2px solid #${palette.accent};
        border-radius: 10px;
        color: #${palette.text};
      }
    '';
  };

  security.pam.services.gtklock = {
    enableGnomeKeyring = true;
    rules.auth.gnome_keyring.settings.auto_start = true;
  };
}
