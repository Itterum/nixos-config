{ ... }:

{
  flake.nixosModules.pcBoot = {
    boot.loader = {
      systemd-boot.enable = false;
      efi.canTouchEfiVariables = true;

      limine = {
        enable = true;
        efiSupport = true;
        efiInstallAsRemovable = false;
        biosSupport = false;
        enableEditor = false;
        maxGenerations = 10;
        secureBoot.enable = false;
      };
    };
  };
}
