{ pkgs, ... }:

let
  cursorName = "macOS";
  cursorSize = 24;
  gtkThemeName = "adw-gtk3-dark";
  iconThemeName = "WhiteSur-dark";
in
{
  home.pointerCursor = {
    package = pkgs.apple-cursor;
    name = cursorName;
    size = cursorSize;
    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;
    theme = {
      package = pkgs.adw-gtk3;
      name = gtkThemeName;
    };
    iconTheme = {
      package = pkgs.whitesur-icon-theme;
      name = iconThemeName;
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "adwaita-dark";
    qt5ctSettings.Appearance = {
      icon_theme = iconThemeName;
      standard_dialogs = "xdgdesktopportal";
      style = "adwaita-dark";
    };
    qt6ctSettings.Appearance = {
      icon_theme = iconThemeName;
      standard_dialogs = "xdgdesktopportal";
      style = "adwaita-dark";
    };
  };

  xdg.configFile."qt5ct/qt5ct.conf".force = true;
  xdg.configFile."qt6ct/qt6ct.conf".force = true;

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    cursor-size = cursorSize;
    cursor-theme = cursorName;
    gtk-theme = gtkThemeName;
    icon-theme = iconThemeName;
  };
}
