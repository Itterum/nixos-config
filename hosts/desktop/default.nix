{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix

    ../../profiles/nixos/workstation.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/programs/kanata.nix
  ];

  networking.hostName = "desktop";

  system.stateVersion = "26.05";
}
