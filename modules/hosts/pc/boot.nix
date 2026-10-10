{ ... }:

{
  flake.nixosModules.pcBoot =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        age
        sbctl
      ];

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
          secureBoot = {
            enable = true;
            autoGenerateKeys = true;
            autoEnrollKeys.enable = false;
          };
        };
      };
    };
}
