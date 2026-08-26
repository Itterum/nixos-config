{ pkgs, ... }:

{
  programs.nix-ld.enable = true;

  environment.systemPackages = with pkgs; [
    distrobox
    jetbrains-toolbox
    nixd
    obsidian
    zed-editor
  ];
}
