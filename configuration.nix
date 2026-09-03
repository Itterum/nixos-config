{ pkgs, ... }:

{
  networking.hostName = "nixos-wsl";

  wsl = {
    enable = true;
    defaultUser = "itterum";
  };

  users.users.itterum = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/itterum";
    createHome = true;
    homeMode = "0700";
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];

    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];

    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  security.sudo.wheelNeedsPassword = false;

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

  home-manager = {
    backupFileExtension = "hm-backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.itterum = import ./home.nix;
  };

  system.stateVersion = "25.05";
}
