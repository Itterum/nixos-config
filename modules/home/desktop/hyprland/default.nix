{ config, lib, pkgs, ... }:

let
  palette = config.itterum.theme.palette;
  render =
    file:
    builtins.replaceStrings
      [
        "@activeBorder@"
        "@inactiveBorder@"
        "@foot@"
        "@quickshell@"
        "@systemctl@"
        "@loginctl@"
      ]
      [
        "rgb(${lib.removePrefix "#" palette.accent})"
        "rgb(${lib.removePrefix "#" palette.muted})"
        (lib.getExe pkgs.foot)
        (lib.getExe pkgs.quickshell)
        (lib.getExe' pkgs.systemd "systemctl")
        (lib.getExe' pkgs.systemd "loginctl")
      ]
      (builtins.readFile file);
in
{
  # Hyprland itself comes from the NixOS module. These are real Lua modules,
  # adapted from Omarchy, rather than Home Manager's settings-to-Lua renderer.
  xdg.configFile = {
    "hypr/hyprland.lua".text = render ./hyprland.lua;
    "hypr/monitors.lua".text = render ./monitors.lua;
    "hypr/input.lua".text = render ./input.lua;
    "hypr/bindings.lua".text = render ./bindings.lua;
    "hypr/looknfeel.lua".text = render ./looknfeel.lua;
    "hypr/autostart.lua".text = render ./autostart.lua;
  };
}
