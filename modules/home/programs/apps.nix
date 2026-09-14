{ pkgs, ... }:

{
  programs.firefox.enable = true;

  home.packages = with pkgs; [
    keepassxc
    nautilus
    obsidian
    telegram-desktop
  ];
}
