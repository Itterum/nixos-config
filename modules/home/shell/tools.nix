{ pkgs, ... }:

{
  home.packages = with pkgs; [
    ripgrep
    fd
    tree
    jq

    fastfetch
    uv

    kubectl
    k9s
    teleport
  ];

  programs = {
    git.enable = true;
    btop.enable = true;

    bat.enable = true;

    eza = {
      enable = true;
      enableZshIntegration = true;
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
