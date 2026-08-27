{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
  ];

  networking.hostName = "nixos";

  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;
}
