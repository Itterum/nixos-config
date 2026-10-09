{ pkgs, ... }:

{
  home.packages = [ pkgs.jetbrains-mono ];

  programs.foot = {
    enable = true;

    settings.main = {
      font = "JetBrains Mono:size=12";
      initial-window-size-chars = "111x33";
    };
  };

  programs.plasma.configFile."kdeglobals".General = {
    TerminalApplication = "foot";
    TerminalService = "foot.desktop";
  };
}
