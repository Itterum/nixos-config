{ pkgs, ... }:

{
  home.username = "itterum";
  home.homeDirectory = "/home/itterum";

  home.stateVersion = "26.05";

  home.packages = with pkgs; [
    htop
    ripgrep
  ];

  programs.git.enable = true;

  programs.bash.enable = true;

  programs.home-manager.enable = true;
}

