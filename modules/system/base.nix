{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    foot
    ghostty
    keepassxc
    nautilus
  ];

  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;
  services.udisks2.enable = true;
  services.gvfs.enable = true;
  services.upower.enable = true;

  system.stateVersion = "26.05";
}
