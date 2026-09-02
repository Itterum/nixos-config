{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/nixos/workstation.nix
    ../../modules/nixos/hardware/nvidia.nix
    ../../modules/nixos/programs/kanata.nix
  ];

  networking.hostName = "desktop";
}
