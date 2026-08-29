{ pkgs, ... }:

{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableZshIntegration = true;

    settings = {
      theme = "Adwaita Dark";
      font-family = "FiraCode Nerd Font";
      font-size = 11;
      background-opacity = 0.9;
      window-decoration = "none";
      window-theme = "dark";
    };

    installVimSyntax = true;
  };
}
