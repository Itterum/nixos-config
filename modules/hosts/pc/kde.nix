{ ... }:

{
  flake.nixosModules.pcKde =
    { pkgs, ... }:
    {
      services.desktopManager.plasma6.enable = true;

      services.displayManager = {
        sddm.enable = true;
        sddm.wayland.enable = true;
        defaultSession = "plasma";
      };

      programs.foot.enable = true;

      environment.plasma6.excludePackages = [ pkgs.kdePackages.konsole ];
    };
}
