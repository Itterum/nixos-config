{ pkgs, ... }:
{
  programs.ghostty = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.ghostty-bin else pkgs.ghostty;

    enableZshIntegration = true;

    # Terminal settings
    settings = {
      theme = "Catppuccin Mocha";
      font-family = "FiraCode Nerd Font";
      font-size = 11;
      background-opacity = 0.9;
      window-decoration = "none";
      window-theme = "dark";
    };

    installVimSyntax = true;
  };
}
