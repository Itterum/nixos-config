{
  config,
  lib,
  pkgs,
  ...
}:

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
in
{
  home.activation.installNiriConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.configHome}/niri"
    run install -m 0644 "${./files/niri/config.kdl}" "${config.xdg.configHome}/niri/config.kdl"
  '';

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

    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    cursor-size = cursorSize;
    cursor-theme = cursorName;
    gtk-theme = gtkThemeName;
  };
}
