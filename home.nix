{ pkgs, ... }:

{
  imports = [
    ./home/zellij.nix
    ./home/emacs.nix
  ];

  home.username = "nixos";
  home.homeDirectory = "/home/nixos";
  home.stateVersion = "26.05";
  home.sessionVariables = {
    COLORTERM = "truecolor";
    EDITOR = "emacs";
    VISUAL = "emacs";
  };

  home.packages = with pkgs; [
    btop
    ripgrep
    fd
    tree
    jq

    fastfetch
    devenv
    uv
    rustup

    kubectl
    k9s
    teleport

    bubblewrap
    codex
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "lyashenko.ivan";
      user.email = "ivan.lyashenko.it@gmail.com";
      init.defaultBranch = "main";
    };
  };
  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
  };

  programs.home-manager.enable = true;
  programs.bash.enable = true;
}
