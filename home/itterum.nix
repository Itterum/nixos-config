{ pkgs, ... }:

let
  nvm = pkgs.fetchFromGitHub {
    owner = "nvm-sh";
    repo = "nvm";
    rev = "v0.40.8";
    hash = "sha256-24FP1brAAyWu+Q0Dk+Y4aXgdCBon9GkBXgFaGXBO7sc=";
  };
in

{
  home.username = "itterum";
  home.homeDirectory = "/home/itterum";

  home.stateVersion = "26.05";

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
  ];

  programs.git = {
    enable = true;
    settings = {
      user.name = "lyashenko.ivan";
      user.email = "ivan.lyashenko.it@gmail.com";
      init.defaultBranch = "main";
    };
  };
  programs.gh.enable = true;
  programs.btop.enable = true;

  programs.bash.enable = true;
  programs.bash.initExtra = ''
    export NVM_DIR="$HOME/.nvm"
    source ${nvm}/nvm.sh
  '';

  home.sessionVariables.NVM_DIR = "$HOME/.nvm";

  programs.starship = {
    enable = true;
    settings.add_newline = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.eza = {
    enable = true;
  };

  programs.fzf = {
    enable = true;
  };

  programs.zoxide = {
    enable = true;
  };

  programs.home-manager.enable = true;
}
