{ pkgs, ... }:

let
  cursorName = "macOS";
  cursorSize = 24;
  gtkThemeName = "catppuccin-mocha-mauve-standard+normal";
  gtkThemePackage = pkgs.catppuccin-gtk.override {
    accents = [ "mauve" ];
    size = "standard";
    tweaks = [ "normal" ];
    variant = "mocha";
  };
  qtThemeName = "catppuccin-mocha-mauve";
  qtThemePackage = pkgs.catppuccin-kvantum.override {
    accent = "mauve";
    variant = "mocha";
  };
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
      package = gtkThemePackage;
      name = gtkThemeName;
    };
    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";
    kvantum = {
      enable = true;
      themes = [ qtThemePackage ];
      settings.General.theme = qtThemeName;
    };
    qt5ctSettings.Appearance = {
      icon_theme = "Papirus-Dark";
      standard_dialogs = "xdgdesktopportal";
      style = "kvantum";
    };
    qt6ctSettings.Appearance = {
      icon_theme = "Papirus-Dark";
      standard_dialogs = "xdgdesktopportal";
      style = "kvantum";
    };
  };

  xdg.configFile."qt5ct/qt5ct.conf".force = true;
  xdg.configFile."qt6ct/qt6ct.conf".force = true;

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    cursor-size = cursorSize;
    cursor-theme = cursorName;
    gtk-theme = gtkThemeName;
    icon-theme = "Papirus-Dark";
  };
}
