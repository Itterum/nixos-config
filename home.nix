{ pkgs, ... }:

{
  imports = [ ./helix.nix ];

  home = {
    username = "itterum";
    homeDirectory = "/home/itterum";
    stateVersion = "26.05";

    packages = with pkgs; [
      codex
      fastfetch
      fd
      jq
      k9s
      kubectl
      nixfmt
      ripgrep
      teleport
      tree
      uv
    ];

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
      COLORTERM = "truecolor";
    };
  };

  programs = {
    home-manager.enable = true;

    git.enable = true;
    gh.enable = true;

    zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;

      initContent = ''
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' menu select
      '';
    };

    starship = {
      enable = true;
      enableZshIntegration = true;
      settings.add_newline = true;
    };

    direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

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
