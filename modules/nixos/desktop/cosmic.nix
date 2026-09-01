{ pkgs, ... }: {
  services = {
    desktopManager.cosmic.enable = true;
    displayManager.cosmic-greeter.enable = true;
    system76-scheduler.enable = true;
  };

  environment.systemPackages = with pkgs; [
      cosmic-ext-applet-caffeine
      cosmic-ext-applet-privacy-indicator
    ];

    environment.cosmic.excludePackages = with pkgs; [
      cosmic-edit
      cosmic-player
      cosmic-reader
      cosmic-term
      cosmic-wallpapers
    ];
}
