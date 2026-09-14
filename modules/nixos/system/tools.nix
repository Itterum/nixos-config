{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    curl
    git
    openssh
    vim
    wget
  ];
}
