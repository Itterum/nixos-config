{ ... }:

{
  imports = [
    ../../modules/nixos/system/fonts.nix
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/nix.nix
    ../../modules/nixos/system/users.nix
    ../../modules/nixos/system/tools.nix
    ../../modules/nixos/desktop/niri.nix
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/desktop/portals.nix
    ../../modules/nixos/desktop/session.nix
    ../../modules/nixos/desktop/greeter.nix
    ../../modules/nixos/desktop/services.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/network/default.nix
    ../../modules/nixos/virtualisation/containers.nix
  ];
}
