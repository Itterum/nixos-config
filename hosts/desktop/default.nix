{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/profiles/workstation.nix
    ../../modules/hardware/nvidia.nix
  ];

  networking.hostName = "desktop";
}
