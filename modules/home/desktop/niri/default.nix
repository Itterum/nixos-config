{
  inputs,
  osConfig,
  ...
}:

{
  imports = [
    inputs.niri-flake.homeModules.config
    ./input.nix
    ./outputs.nix
    ./appearance.nix
    ./animations.nix
    ./startup.nix
    ./rules.nix
    ./binds
  ];

  xdg.configFile.niri-config.force = true;

  programs.niri = {
    package = osConfig.programs.niri.package;
    settings = {
      config-notification.disable-failed = true;
      hotkey-overlay.skip-at-startup = true;
      environment.XDG_CURRENT_DESKTOP = "niri";
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      prefer-no-csd = true;
      debug.honor-xdg-activation-with-invalid-serial = [ ];
    };
  };
}
