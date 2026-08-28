{ ... }:

{
  imports = [
    ../../profiles/home/workstation.nix
  ];

  home.username = "itterum";
  home.homeDirectory = "/home/itterum";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
