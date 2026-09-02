{ pkgs, ... }:

{
  home.packages = with pkgs; [
    keepassxc
    nautilus
    telegram-desktop
    obsidian
    kooha
    gradia
    pi-coding-agent
  ];
}
