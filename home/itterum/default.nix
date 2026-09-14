{
  imports = [ ../../profiles/home/workstation.nix ];

  home = {
    username = "itterum";
    homeDirectory = "/home/itterum";
    stateVersion = "26.05";
  };

  programs.home-manager.enable = true;
}
