{ pkgs, ... }:

let
  qs = "${pkgs.quickshell}/bin/qs";
in
{
  wayland.windowManager.hyprland.settings.bind = [
    "SUPER, Return, exec, ${pkgs.foot}/bin/foot"
    "SUPER, Space, exec, ${qs} ipc call shell toggle omarchy.menu '{}'"
    "SUPER SHIFT, R, exec, ${pkgs.systemd}/bin/systemctl --user restart itterum-shell.service"
    "SUPER ALT, L, exec, ${qs} ipc call shell summon omarchy.lock '{}'"
    "SUPER SHIFT, E, exec, ${pkgs.systemd}/bin/loginctl terminate-user $USER"
  ];
}
