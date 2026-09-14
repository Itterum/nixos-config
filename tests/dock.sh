#!/usr/bin/env bash

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
flake_ref="path:$root#nixosConfigurations.desktop.config.home-manager.users.itterum"

fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$1"; }

config_files=$(nix eval --json "$flake_ref.xdg.configFile")
dock=$(jq -r '."itterum-shell/arc-dock.json".text // empty' <<<"$config_files")
[[ -n $dock ]] || fail "Arc Dock configuration is managed by Home Manager"
[[ $(jq -r '.settings.dockTheme' <<<"$dock") == theme ]] || fail "Arc Dock follows Kanagawa"
[[ $(jq -r '.settings.magnifyScale' <<<"$dock") == 111 ]] || fail "Arc Dock uses restrained magnification"
pass "Arc Dock configuration follows the workstation theme"

shell_json=$(jq -r '."itterum-shell/shell.json".text' <<<"$config_files")
jq -e '.plugins | any(.id == "io.github.claudsondouglas.arcdock")' <<<"$shell_json" >/dev/null \
  || fail "Arc Dock is enabled"
pass "Arc Dock is enabled declaratively"

hyprland=$(nix eval --json "$flake_ref.wayland.windowManager.hyprland.settings")
jq -e '.layerrule | any(test("blur.*arc-dock"))' <<<"$hyprland" >/dev/null \
  || fail "Arc Dock blur is declared in the compositor configuration"
pass "Arc Dock blur is declared in the compositor configuration"
