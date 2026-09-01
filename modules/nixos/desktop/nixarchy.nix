{ inputs, ... }:

{
  imports = [
    inputs.nixarchy.nixosModules.nixarchy
    ../../../nixarchy-apps.nix
  ];

  programs.nixarchy = {
    enable = true;
    user = "itterum";
    flake = "/home/itterum/nixos-config";
    displayManager = true;
    browserThemeUser = null;
    binaryCaches = true;
  };
}
