{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/nixos/workstation.nix
  ];

  networking.hostName = "nixos";

  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;
}
