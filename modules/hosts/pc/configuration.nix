{ self, inputs, ... }:

{
  flake.nixosModules.pcConfig = { pkgs, ... }: {
    imports = [
      self.nixosModules.pcDesktopApps
      self.nixosModules.pcDocker
      self.nixosModules.pcHardware
      self.nixosModules.pcJetBrains
      self.nixosModules.pcNvidia
      self.nixosModules.pcStorage
      self.nixosModules.pcSunshine
      self.nixosModules.gptApp

      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;

    home-manager.users.itterum = {
      imports = [
        self.homeModules.github
        self.homeModules.gnome
        self.homeModules.helix
        self.homeModules.zedEditor

        ../../../home/itterum.nix
      ];
    };

    nix.settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;

    networking.hostName = "pc";
    networking.networkmanager.enable = true;

    time.timeZone = "Europe/Chisinau";
    i18n.defaultLocale = "en_US.UTF-8";

    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    services.xserver.xkb = {
      layout = "us";
      variant = "";
    };

    services.printing.enable = true;

    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };

    users.users.itterum = {
      isNormalUser = true;
      description = "itterum";
      extraGroups = [
        "networkmanager"
        "uinput"
        "wheel"
      ];
      packages = with pkgs; [ ];
    };

    programs.nix-ld.enable = true;
    programs.firefox.enable = true;

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
      vim
      wget
      curl
    ];

    system.stateVersion = "26.05";
  };
}
