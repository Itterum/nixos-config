# Bootstrap hardware module for evaluation only.
# Replace this entire file with the output generated on the desktop before
# running nixos-install; see README.md.
{ lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # This deliberately nonexistent label satisfies NixOS module evaluation but
  # cannot boot, making an accidental installation of the bootstrap obvious.
  fileSystems."/" = {
    device = "/dev/disk/by-label/REPLACE_ME_DESKTOP_ROOT";
    fsType = "btrfs";
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  warnings = [
    "desktop uses the bootstrap hardware configuration; replace it before installation"
  ];
}
