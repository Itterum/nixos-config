#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
flake_ref="path:${repo_root}"
nix=(nix --extra-experimental-features "nix-command flakes")

fail() {
  printf '%s\n' "$1" >&2
  exit 1
}

assert_eq() {
  local expected=$1
  local actual=$2
  local label=$3

  [[ "$actual" == "$expected" ]] ||
    fail "${label}: expected ${expected}, got ${actual}"
}

assert_contains() {
  local needle=$1
  local haystack=$2
  local label=$3

  [[ "$haystack" == *"$needle"* ]] ||
    fail "${label}: expected output to contain ${needle}"
}

assert_not_contains() {
  local needle=$1
  local haystack=$2
  local label=$3

  [[ "$haystack" != *"$needle"* ]] ||
    fail "${label}: output unexpectedly contains ${needle}"
}

flake_json() {
  local option=$1
  "${nix[@]}" eval --json \
    "${flake_ref}#nixosConfigurations.wsl.config.${option}"
}

flake_raw() {
  local option=$1
  "${nix[@]}" eval --raw \
    "${flake_ref}#nixosConfigurations.wsl.config.${option}"
}

assert_eq \
  '["wsl"]' \
  "$("${nix[@]}" eval --json \
    "${flake_ref}#nixosConfigurations" --apply builtins.attrNames)" \
  "flake configurations"

assert_eq '"nixos-wsl"' "$(flake_json networking.hostName)" "hostname"
assert_eq "true" "$(flake_json wsl.enable)" "NixOS-WSL"
assert_eq '"itterum"' "$(flake_json wsl.defaultUser)" "default user"
assert_eq "1000" "$(flake_json users.users.itterum.uid)" "UID"
assert_eq '"/home/itterum"' "$(flake_json users.users.itterum.home)" "home"
assert_contains "zsh" "$(flake_raw users.users.itterum.shell)" "login shell"
assert_eq '"25.05"' "$(flake_json system.stateVersion)" "system state version"
assert_eq \
  '"26.05"' \
  "$(flake_json home-manager.users.itterum.home.stateVersion)" \
  "home state version"

assert_eq "true" "$(flake_json virtualisation.podman.enable)" "Podman"
assert_eq \
  "true" \
  "$(flake_json virtualisation.podman.dockerCompat)" \
  "Docker compatibility"

for option in \
  programs.zsh.enable \
  home-manager.users.itterum.programs.home-manager.enable \
  home-manager.users.itterum.programs.zsh.enable \
  home-manager.users.itterum.programs.git.enable \
  home-manager.users.itterum.programs.gh.enable \
  home-manager.users.itterum.programs.helix.enable \
  home-manager.users.itterum.programs.starship.enable \
  home-manager.users.itterum.programs.direnv.enable \
  home-manager.users.itterum.programs.direnv.nix-direnv.enable \
  home-manager.users.itterum.programs.tmux.enable \
  home-manager.users.itterum.programs.btop.enable \
  home-manager.users.itterum.programs.bat.enable \
  home-manager.users.itterum.programs.eza.enable \
  home-manager.users.itterum.programs.fzf.enable \
  home-manager.users.itterum.programs.zoxide.enable; do
  assert_eq "true" "$(flake_json "$option")" "$option"
done

home_packages=$(flake_json home-manager.users.itterum.home.packages)
for package in \
  codex kubectl k9s teleport uv ripgrep fd tree jq fastfetch nixfmt; do
  assert_contains "$package" "$home_packages" "home package ${package}"
done

system_packages=$(flake_json environment.systemPackages)
for package in git curl wget vim openssh; do
  assert_contains "$package" "$system_packages" "system package ${package}"
done

for forbidden in \
  distrobox niri noctalia brave google-chrome chatgpt \
  telegram-desktop obsidian ghostty zed-editor; do
  assert_not_contains "$forbidden" "$home_packages" "forbidden package ${forbidden}"
  assert_not_contains "$forbidden" "$system_packages" "forbidden system package ${forbidden}"
done

for option in \
  services.xserver.enable \
  services.displayManager.gdm.enable \
  services.displayManager.sddm.enable; do
  assert_eq "false" "$(flake_json "$option")" "$option"
done

helix_language_names=$(
  "${nix[@]}" eval --json \
    "${flake_ref}#nixosConfigurations.wsl.config.home-manager.users.itterum.programs.helix.languages.language" \
    --apply 'languages: builtins.map (language: language.name) languages'
)
assert_eq \
  '["typescript","tsx","javascript","jsx","rust","python","c-sharp","nix","qml","json","toml","markdown","bash","kdl"]' \
  "$helix_language_names" \
  "Helix language set and uniqueness"

printf 'WSL CLI configuration checks passed\n'
