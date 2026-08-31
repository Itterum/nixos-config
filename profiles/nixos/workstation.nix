{ ... }:

{
  imports = [
    ../../modules/nixos/system/base.nix
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/desktop/greeter.nix
    ../../modules/nixos/desktop/session.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/network/casting.nix
    ../../modules/nixos/programs/browsers.nix
    ../../modules/nixos/programs/chatgpt.nix
    ../../modules/nixos/virtualisation/containers.nix
  ];
}
