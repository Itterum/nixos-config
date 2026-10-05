{ self, inputs, ... }:

{
  flake.nixosModules.wslConfig = {
    imports = [
      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.users.itterum = {
      imports = [
        self.homeModules.helix

        ../../../home/itterum.nix
      ];
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    wsl = {
      enable = true;
      defaultUser = "itterum";
      wslConf.automount.options = "metadata,uid=1001,gid=100";
    };

    networking.hostName = "nixos-wsl";
    time.timeZone = "Europe/Minsk";
    i18n.defaultLocale = "en_US.UTF-8";

    users.users = {
      nixos = {
        isNormalUser = true;
        uid = 1000;
        home = "/home/nixos";
        extraGroups = [ "wheel" ];
      };

      itterum = {
        uid = 1001;
        extraGroups = [ "docker" ];
      };
    };

    programs.nix-ld.enable = true;
    virtualisation.docker.enable = true;

    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "26.05";
  };
}
