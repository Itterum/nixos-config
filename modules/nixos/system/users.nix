{ pkgs, ... }:

{
  programs.zsh.enable = true;

  users.users.itterum = {
    isNormalUser = true;
    description = "itterum";
    shell = pkgs.zsh;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
