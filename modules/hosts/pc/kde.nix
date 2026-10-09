{ ... }:

{
  flake.nixosModules.pcKde =
    { pkgs, ... }:
    let
      wallpaper = ../../../home/kde/assets/nix-wallpaper.png;
      sddmTheme = pkgs.runCommand "nixos-breeze-sddm-theme" { } ''
        theme="$out/share/sddm/themes/nixos-breeze"
        mkdir -p "$theme"
        cp -r ${pkgs.kdePackages.plasma-desktop}/share/sddm/themes/breeze/. "$theme/"
        chmod -R u+w "$theme"
        sed -i 's|^background=.*|background=${wallpaper}|' "$theme/theme.conf"
      '';
    in
    {
      services.desktopManager.plasma6.enable = true;

      services.displayManager = {
        sddm.enable = true;
        sddm.wayland.enable = true;
        sddm.theme = "${sddmTheme}/share/sddm/themes/nixos-breeze";
        defaultSession = "plasma";
      };

      programs.foot.enable = true;

      environment.plasma6.excludePackages = [ pkgs.kdePackages.konsole ];
    };
}
