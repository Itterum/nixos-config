{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    sbctl
    wireguard-tools
  ];
}
