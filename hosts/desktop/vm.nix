{ pkgs, ... }:

{
  virtualisation = {
    memorySize = 8192;
    cores = 4;
    diskSize = 32768;
    graphics = true;
    qemu.options = [
      "-vga none"
      "-device virtio-vga"
      "-display gtk,gl=off,grab-on-hover=on"
    ];
  };

  environment.sessionVariables = {
    LIBGL_ALWAYS_SOFTWARE = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
  };

  services.greetd.settings.initial_session = {
    user = "itterum";
    command = "${pkgs.uwsm}/bin/uwsm start -e -D Hyprland hyprland.desktop";
  };

  # A recovery login for the disposable VM only; the physical host has no
  # declarative password and keeps the normal greetd login screen.
  users.users.itterum.initialPassword = "itterum";
}
