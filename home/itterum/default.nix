{ ... }:

{
  imports = [
    ./desktop.nix
    ./shell.nix
    ../../modules/programs/ghostty.nix
    ../../modules/programs/helix.nix
    ../../modules/programs/zed.nix
  ];

  home.username = "itterum";
  home.homeDirectory = "/home/itterum";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
