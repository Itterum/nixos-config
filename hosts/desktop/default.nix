{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ../../profiles/nixos/workstation.nix
  ];

  networking.hostName = "desktop";
  system.stateVersion = "26.05";
}
