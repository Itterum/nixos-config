{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/base.nix
    ../../modules/hardware/bluetooth.nix
    ../../modules/desktop/niri.nix
    ../../modules/desktop/dms.nix
    ../../modules/desktop/portals.nix
    ../../modules/desktop/audio.nix
    ../../modules/programs/browsers.nix
    ../../modules/programs/chatgpt.nix
    ../../modules/programs/development.nix
    ../../modules/programs/shell.nix
    ../../modules/virtualisation/containers.nix
  ];
}
