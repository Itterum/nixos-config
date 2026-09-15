#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
flake_ref="path:${repo_root}"
home_prefix="nixosConfigurations.desktop.config.home-manager.users.itterum"

flake_json() {
  nix eval --json "${flake_ref}#${home_prefix}.$1"
}

assert_eq() {
  [[ $1 == "$2" ]] || {
    printf '%s: expected %q, got %q\n' "$3" "$1" "$2" >&2
    return 1
  }
}

assert_contains() {
  [[ $2 == *"$1"* ]] || {
    printf '%s: expected value to contain %q\n' "$3" "$1" >&2
    return 1
  }
}

assert_eq '"kanagawa"' "$(flake_json itterum.theme.name)" "theme name"
assert_eq '"dark"' "$(flake_json itterum.theme.colorScheme)" "theme color scheme"
assert_eq '"#1f1f28"' "$(flake_json itterum.theme.palette.background)" "Kanagawa background"
assert_eq '"#dcd7ba"' "$(flake_json itterum.theme.palette.foreground)" "Kanagawa foreground"
assert_eq '"#dcd7ba"' "$(flake_json itterum.theme.palette.accent)" "Kanagawa accent"

config_files=$(flake_json xdg.configFile)
hypr_look=$(jq -r '."hypr/looknfeel.lua".text' <<<"$config_files")
assert_contains 'dcd7ba' "$hypr_look" "Hyprland shared accent"
colors=$(jq -r '."itterum-shell/theme/colors.toml".text' <<<"$config_files")
assert_contains '#1f1f28' "$colors" "shell background"
assert_contains '#dcd7ba' "$colors" "shell foreground"
assert_contains 'accent = "#dcd7ba"' "$colors" "shell accent"

assert_eq '"prefer-dark"' "$(flake_json dconf.settings."org/gnome/desktop/interface".color-scheme)" "GTK dark preference"

assert_eq '"Bibata-Modern-Classic"' "$(flake_json home.pointerCursor.name)" "cursor name"
assert_eq '16' "$(flake_json home.pointerCursor.size)" "cursor size"
assert_contains 'bibata-cursors' "$(flake_json home.pointerCursor.package)" "cursor package"
assert_eq '"Bibata-Modern-Classic"' "$(flake_json dconf.settings."org/gnome/desktop/interface".cursor-theme)" "dconf cursor"
assert_contains 'hl.env("XCURSOR_THEME", "Bibata-Modern-Classic")' "$hypr_look" "Hyprland cursor name"
assert_contains 'hl.env("XCURSOR_SIZE", "16")' "$hypr_look" "Hyprland cursor size"

printf 'theme regression checks passed\n'
