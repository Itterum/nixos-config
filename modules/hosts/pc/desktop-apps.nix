{ ... }:

{
  flake.nixosModules.pcDesktopApps = { pkgs, ... }: {
    services.flatpak.enable = true;

    environment.systemPackages = with pkgs; [
      bazaar
      google-chrome
      keepassxc
      ptyxis
    ];

    systemd.services.flatpak-flathub = {
      description = "Add the Flathub Flatpak repository";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [
        "flatpak-system-helper.service"
        "network-online.target"
      ];

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.flatpak}/bin/flatpak remote-add --system --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        '';
      };
    };
  };
}
