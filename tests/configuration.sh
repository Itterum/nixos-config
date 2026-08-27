#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
flake_ref="path:${repo_root}"

assert_eq() {
  local expected=$1
  local actual=$2
  local label=$3

  if [[ "$actual" != "$expected" ]]; then
    printf '%s: expected %q, got %q\n' "$label" "$expected" "$actual" >&2
    return 1
  fi
}

assert_contains() {
  local needle=$1
  local haystack=$2
  local label=$3

  if [[ "$haystack" != *"$needle"* ]]; then
    printf '%s: expected %q to contain %q\n' "$label" "$haystack" "$needle" >&2
    return 1
  fi
}

assert_not_contains() {
  local needle=$1
  local haystack=$2
  local label=$3

  if [[ "$haystack" == *"$needle"* ]]; then
    printf '%s: expected %q not to contain %q\n' "$label" "$haystack" "$needle" >&2
    return 1
  fi
}

flake_value() {
  local host=$1
  local option=$2
  nix eval --raw "${flake_ref}#nixosConfigurations.${host}.config.${option}"
}

flake_json() {
  local host=$1
  local option=$2
  nix eval --json "${flake_ref}#nixosConfigurations.${host}.config.${option}"
}

dms_value() {
  local expression=$1
  nix eval --raw --impure --expr "
    let
      settings = builtins.fromJSON (
        builtins.readFile ${repo_root}/home/itterum/files/dms/settings.json
      );
    in toString (${expression})
  "
}

assert_eq "nixos" "$(flake_value laptop networking.hostName)" "laptop hostname"
assert_eq "desktop" "$(flake_value desktop networking.hostName)" "desktop hostname"

assert_eq "true" "$(flake_json laptop boot.loader.limine.enable)" "laptop Limine"
assert_eq "true" "$(flake_json desktop boot.loader.limine.enable)" "desktop Limine"
assert_eq "true" "$(flake_json laptop services.tlp.enable)" "laptop TLP"
assert_eq "false" "$(flake_json desktop services.tlp.enable)" "desktop TLP"

assert_not_contains \
  '"nvidia"' \
  "$(flake_json laptop services.xserver.videoDrivers)" \
  "laptop video drivers"
assert_contains \
  '"nvidia"' \
  "$(flake_json desktop services.xserver.videoDrivers)" \
  "desktop video drivers"
assert_eq "true" "$(flake_json desktop hardware.graphics.enable)" "desktop graphics"
assert_eq "true" "$(flake_json desktop hardware.nvidia.modesetting.enable)" "NVIDIA modesetting"
assert_eq "true" "$(flake_json desktop hardware.nvidia.open)" "NVIDIA open module"
assert_eq \
  "$(flake_value desktop boot.kernelPackages.nvidiaPackages.stable.version)" \
  "$(flake_value desktop hardware.nvidia.package.version)" \
  "NVIDIA stable package"

assert_eq "4" "$(dms_value 'settings.cornerRadius')" "DMS corner radius"
assert_eq "8" "$(dms_value 'settings.niriLayoutGapsOverride')" "DMS Niri gaps"
assert_eq \
  "FiraCode Nerd Font Mono" \
  "$(dms_value 'settings.monoFontFamily')" \
  "DMS monospace font"
assert_eq \
  '{"enabled":true,"id":"workspaceSwitcher"}' \
  "$(dms_value 'builtins.toJSON (builtins.elemAt (builtins.elemAt settings.barConfigs 0).leftWidgets 1)')" \
  "DMS workspace switcher"

printf 'configuration regression checks passed\n'
