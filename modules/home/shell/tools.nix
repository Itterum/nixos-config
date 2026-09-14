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
    git = {
      enable = true;
      settings = {
        user.name = "itterum";
        user.email = "ivan.lyashenko.it@gmail.com";
        init.defaultBranch = "main";
      };
    };
    gh.enable = true;
    tmux = {
      enable = true;
      clock24 = true;
      mouse = true;
      terminal = "screen-256color";
    };
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
