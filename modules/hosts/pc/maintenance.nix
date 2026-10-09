{ ... }:

{
  flake.nixosModules.pcMaintenance = {
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    boot.loader.systemd-boot.configurationLimit = 10;
  };
}
