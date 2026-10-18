{ self, inputs, ... }:

{
  flake.nixosModules.wslConfig =
    { pkgs, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.users.nixos = {
        imports = [
          self.homeModules.foot
          self.homeModules.github
          self.homeModules.helix
          self.homeModules.kde
          self.homeModules.zedEditor

          ../../../home/nixos.nix
        ];
      };

      nixpkgs.hostPlatform = "x86_64-linux";
      nixpkgs.config.allowUnfree = true;

      wsl = {
        enable = true;
        defaultUser = "nixos";
      };

      users.users.nixos = {
        isNormalUser = true;
        uid = 1000;
        home = "/home/nixos";
        extraGroups = [ "docker" ];
      };

      weaselway = {
        enable = true;
        session = "plasma";
      };

      services.desktopManager.plasma6.enable = true;
      services.displayManager.sddm.enable = false;

      environment.plasma6.excludePackages = with pkgs.kdePackages; [
        elisa
        konsole
        kwin-x11
        krdp
        plasma-workspace-wallpapers
      ];
      programs.kde-pim.enable = false;
      services.fwupd.enable = false;
      services.orca.enable = false;
      services.speechd.enable = false;

      virtualisation.docker.enable = true;

      nix.channel.enable = false;
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      programs.git.enable = true;
      programs.nix-ld.enable = true;

      environment.systemPackages = [ pkgs.brave ];

      networking.hostName = "nixos";
      system.stateVersion = "26.05";
    };
}
