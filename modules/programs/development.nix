{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    distrobox
    jetbrains-toolbox
    obsidian
    zed-editor
  ];
}
