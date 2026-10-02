{ self, inputs, ... }: {

  flake.nixosModules.vmConfig = { pkgs, lib, ... }: {
    # import any other modules from here
    imports = [
      self.nixosModules.vmHardware
      self.nixosModules.gptApp

      inputs.home-manager.nixosModules.home-manager
    ];

    home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  home-manager.users.itterum = {
    imports = [
      self.homeModules.gnome
      self.homeModules.helix
      self.homeModules.zedEditor

      ../../../home/itterum.nix
    ];
  };

    nix.settings.experimental-features = [ "nix-command" "flakes" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos"; # Define your hostname.

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

  users.users."itterum" = {
    isNormalUser = true;
    description = "itterum";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    ];
  };

  programs.firefox.enable = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    curl
    git
  ];

  services.flatpak.enable = true;

  system.stateVersion = "26.05"; # Did you read the comment?
  };
}
