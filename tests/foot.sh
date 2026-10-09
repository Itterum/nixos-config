#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
flake="builtins.getFlake \"path:$root\""
settings="$(nix eval --json --impure --expr "
  let
    user = ($flake).nixosConfigurations.pc.config.home-manager.users.itterum;
  in
    user.programs.foot.settings or {}
")"
kde_terminal="$(nix eval --json --impure --expr "
  let
    user = ($flake).nixosConfigurations.pc.config.home-manager.users.itterum;
  in {
    application = user.programs.plasma.configFile.\"kdeglobals\".General.TerminalApplication.value or \"\";
    service = user.programs.plasma.configFile.\"kdeglobals\".General.TerminalService.value or \"\";
  }
")"
font_installed="$(nix eval --json --impure --expr "
  let
    pc = ($flake).nixosConfigurations.pc;
  in
    builtins.elem pc.pkgs.jetbrains-mono pc.config.home-manager.users.itterum.home.packages
")"

jq -e '
  .main.font == "JetBrains Mono:size=12" and
  .main."initial-window-size-chars" == "111x33"
' <<<"$settings" >/dev/null
jq -e '
  .application == "foot" and
  .service == "foot.desktop"
' <<<"$kde_terminal" >/dev/null
test "$font_installed" = true

echo "Foot settings and KDE terminal integration assertions passed"
