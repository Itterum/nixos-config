{ pkgs, ... }:

let
  launchHelix = pkgs.writeShellScript "itterum-launch-helix" ''
    exec ${pkgs.foot}/bin/foot ${pkgs.helix}/bin/hx
  '';
  launchCodex = pkgs.writeShellScript "itterum-launch-codex" ''
    exec ${pkgs.foot}/bin/foot --title="Codex CLI" ${pkgs.codex}/bin/codex
  '';
  launchZellij = pkgs.writeShellScript "itterum-launch-zellij" ''
    exec ${pkgs.foot}/bin/foot ${pkgs.zellij}/bin/zellij
  '';
in
{
  xdg.desktopEntries = {
    itterum-helix = {
      name = "Helix";
      genericName = "Text Editor";
      icon = "helix";
      exec = toString launchHelix;
      categories = [ "Development" "TextEditor" ];
      terminal = false;
    };
    itterum-codex-cli = {
      name = "Codex CLI";
      genericName = "Coding Agent";
      icon = "utilities-terminal";
      exec = toString launchCodex;
      categories = [ "Development" ];
      terminal = false;
    };
    itterum-zellij = {
      name = "Zellij";
      genericName = "Terminal Workspace";
      icon = "utilities-terminal";
      exec = toString launchZellij;
      categories = [ "System" "TerminalEmulator" ];
      terminal = false;
    };
  };
}
