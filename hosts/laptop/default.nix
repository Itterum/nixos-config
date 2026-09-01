{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../profiles/nixos/workstation.nix
  ];

  networking.hostName = "nixos";

  services = {
    tlp = {
      enable = true;
      pd.enable = true;
    };

    power-profiles-daemon.enable = false;
  };
}
