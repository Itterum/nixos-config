{ pkgs, ... }:

{
  boot.loader = {
    systemd-boot.enable = false;

    efi.canTouchEfiVariables = true;

    limine = {
      enable = true;
      secureBoot.enable = true;
      # enrollConfig = true;

      maxGenerations = 5;

      extraEntries = ''
        /Windows 11
        protocol: efi_boot_entry
        entry: Windows Boot Manager
      '';
    };

    timeout = 15;
  };

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
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };

  programs.zsh.enable = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nixpkgs.config.allowUnfree = true;

  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    git
    keepassxc
    nautilus
    fastfetch
    btop
    wireguard-tools
    telegram-desktop
    distrobox
    obsidian
    kooha
    gradia
    sbctl
    uv
    teleport
    kubectl
    k9s
  ];

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  services.flatpak.enable = true;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;

  system.stateVersion = "26.05";
}
