{ pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = false;

    efi.canTouchEfiVariables = true;

    limine = {
      enable = true;

      maxGenerations = 5;

      extraEntries = ''
        /Windows 11
        protocol: efi_boot_entry
        entry: Windows Boot Manager
      '';
    };

    timeout = 15;
  };

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "ctrl:nocaps,grp:shifts_toggle";
  };

  users.users.itterum = {
    isNormalUser = true;
    description = "itterum";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    foot
    ghostty
    keepassxc
    nautilus
    fastfetch
    btop
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;

  system.stateVersion = "26.05";
}
