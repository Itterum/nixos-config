{ lib, pkgs, ... }:

let
  chatgptLinux = pkgs.callPackage ../../../packages/chatgpt-linux.nix { };
  desktopIds = [
    "itterum-helix"
    "dev.zed.Zed"
    "foot"
    "itterum-codex-cli"
    "chatgpt"
    "obsidian"
    "bruno"
    "org.gnome.Nautilus"
    "org.gnome.DiskUtility"
    "itterum-zellij"
    "org.telegram.desktop"
    "com.brave.Browser"
    "com.google.Chrome"
  ];
in
{
  options.itterum.applications.desktopIds = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    readOnly = true;
    default = desktopIds;
  };

  config = {
    programs.firefox.enable = false;

    home.packages = [
      pkgs.codex
      chatgptLinux
      pkgs.obsidian
      pkgs.bruno
      pkgs.nautilus
      pkgs.gnome-disk-utility
      pkgs.telegram-desktop
      pkgs.brave
      pkgs.google-chrome
      pkgs.xwayland-satellite
    ];
  };
}
