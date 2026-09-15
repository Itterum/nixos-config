{
  imports = [
    ./hardware-configuration.nix
    ./boot.nix
    ../../profiles/nixos/workstation.nix
  ];

  networking.hostName = "desktop";

  # Keep VM-specific resources and automatic login out of the physical host.
  virtualisation.vmVariant.imports = [ ./vm.nix ];

  system.stateVersion = "26.05";
}
