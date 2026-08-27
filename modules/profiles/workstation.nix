{ ... }:

{
  imports = [
    ../system/base.nix
    ../hardware/bluetooth.nix
    ../network/casting.nix
    ../desktop/niri.nix
    ../desktop/dms.nix
    ../desktop/portals.nix
    ../desktop/audio.nix
    ../programs/browsers.nix
    ../programs/chatgpt.nix
    ../programs/development.nix
    ../programs/shell.nix
    ../virtualisation/containers.nix
  ];
}
