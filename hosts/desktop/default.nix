{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/nixos/workstation.nix
    ../../modules/nixos/hardware/nvidia.nix
  ];

  networking.hostName = "desktop";
}
