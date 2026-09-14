{
  services.displayManager.defaultSession = "hyprland-uwsm";

  # Keep the future compositor module in-tree without activating it on the
  # workstation until the shell's compositor facade gains a Niri backend.
  programs.niri.enable = false;
}
