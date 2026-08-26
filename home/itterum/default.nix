{ config, pkgs, ... }:

{
  home.username = "itterum";
  home.homeDirectory = "/home/itterum";
  home.stateVersion = "26.05";

  home.pointerCursor = {
    gtk.enable = true;       
    x11.enable = true;       
    hyprcursor.enable = true; 
    
    package = pkgs.catppuccin-cursors; 
    name = "catppuccin-mocha-dark-cursors"; 
    size = 16;
  };

  programs.home-manager.enable = true;
}
