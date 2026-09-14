{ pkgs, ... }:

{
  networking.hostName = "nixos";

  users.users.itterum = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/itterum";
    createHome = true;
    shell = pkgs.zsh;
  };

  programs = {
    nix-ld.enable = true;
    zsh.enable = true;
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];

    optimise.automatic = true;

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    curl
    git
    openssh
    vim
    wget
  ];

  system.stateVersion = "26.05";
}
