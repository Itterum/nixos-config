{ pkgs, ... }:

let
  extensions = [
    (pkgs.callPackage ./global-menu.nix { })
    pkgs.gnomeExtensions.just-perfection
    pkgs.gnomeExtensions.caffeine
    pkgs.gnomeExtensions.rounded-window-corners-reborn
    pkgs.gnomeExtensions.overview-background
    pkgs.gnomeExtensions.dash2dock-lite
    pkgs.gnomeExtensions.appindicator
  ];
in
{
  home.packages = extensions;

  dconf.settings."org/gnome/shell".enabled-extensions = map (
    extension: extension.extensionUuid
  ) extensions;
}
