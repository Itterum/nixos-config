#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
flake_ref="path:${repo_root}"

assert_eq() {
  local expected=$1
  local actual=$2
  local label=$3
  if [[ $actual != "$expected" ]]; then
    printf '%s: expected %q, got %q\n' "$label" "$expected" "$actual" >&2
    return 1
  fi
}

assert_contains() {
  local needle=$1
  local haystack=$2
  local label=$3
  if [[ $haystack != *"$needle"* ]]; then
    printf '%s: expected %q to contain %q\n' "$label" "$haystack" "$needle" >&2
    return 1
  fi
}

assert_not_contains() {
  local needle=$1
  local haystack=$2
  local label=$3
  if [[ $haystack == *"$needle"* ]]; then
    printf '%s: expected %q not to contain %q\n' "$label" "$haystack" "$needle" >&2
    return 1
  fi
}

assert_file_exists() {
  [[ -f $1 ]] || { printf 'expected file to exist: %s\n' "$1" >&2; return 1; }
}

assert_path_absent() {
  [[ ! -e $1 ]] || { printf 'expected path to be absent: %s\n' "$1" >&2; return 1; }
}

flake_value() {
  nix eval --raw "${flake_ref}#nixosConfigurations.$1.config.$2"
}

flake_json() {
  nix eval --json "${flake_ref}#nixosConfigurations.$1.config.$2"
}

assert_eq \
  '["desktop"]' \
  "$(nix eval --json "${flake_ref}#nixosConfigurations" --apply builtins.attrNames)" \
  "flake configurations"
assert_eq "desktop" "$(flake_value desktop networking.hostName)" "desktop hostname"
assert_eq '"26.05"' "$(flake_json desktop system.stateVersion)" "system state version"
assert_eq \
  '"26.05"' \
  "$(flake_json desktop home-manager.users.itterum.home.stateVersion)" \
  "home state version"

assert_eq "true" "$(flake_json desktop boot.loader.systemd-boot.enable)" "systemd-boot"
assert_eq "true" "$(flake_json desktop programs.niri.enable)" "Niri"
assert_eq "true" "$(flake_json desktop services.greetd.enable)" "greetd"
assert_eq "true" "$(flake_json desktop services.pipewire.enable)" "PipeWire"
assert_eq "true" "$(flake_json desktop networking.networkmanager.enable)" "NetworkManager"
assert_eq "true" "$(flake_json desktop hardware.bluetooth.enable)" "Bluetooth"
assert_eq "true" "$(flake_json desktop xdg.portal.enable)" "desktop portals"
assert_eq "true" "$(flake_json desktop security.polkit.enable)" "polkit"
assert_eq "true" "$(flake_json desktop services.gnome.gnome-keyring.enable)" "GNOME Keyring"
for service in udisks2 gvfs upower; do
  assert_eq "true" "$(flake_json desktop services.${service}.enable)" "$service"
done
assert_eq "true" "$(flake_json desktop virtualisation.podman.enable)" "Podman"
user_groups=$(flake_json desktop users.users.itterum.extraGroups)
assert_contains '"wheel"' "$user_groups" "wheel membership"
assert_contains '"networkmanager"' "$user_groups" "NetworkManager membership"
assert_eq "false" "$(flake_json desktop boot.loader.limine.enable)" "Limine disabled"
assert_not_contains '"nvidia"' "$(flake_json desktop services.xserver.videoDrivers)" "generic graphics"

home_prefix="home-manager.users.itterum"
for program in zsh starship direnv git ghostty firefox helix; do
  assert_eq "true" "$(flake_json desktop ${home_prefix}.programs.${program}.enable)" "$program"
done
assert_eq \
  "true" \
  "$(flake_json desktop ${home_prefix}.programs.direnv.nix-direnv.enable)" \
  "nix-direnv"
home_packages=$(flake_json desktop ${home_prefix}.home.packages)
for package in ripgrep fd jq tree uv kubectl k9s codex nautilus keepassxc telegram-desktop obsidian; do
  assert_contains "$package" "$home_packages" "$package package"
done

for program in waybar fuzzel swaylock; do
  assert_eq "true" "$(flake_json desktop ${home_prefix}.programs.${program}.enable)" "$program"
done
for service in mako swayidle; do
  assert_eq "true" "$(flake_json desktop ${home_prefix}.services.${service}.enable)" "$service"
done
assert_contains \
  '"graphical-session.target"' \
  "$(flake_json desktop ${home_prefix}.systemd.user.services.swaybg.Install.WantedBy)" \
  "swaybg user service"
niri_config=$(flake_value desktop ${home_prefix}.programs.niri.finalConfig)
assert_contains 'spawn "fuzzel"' "$niri_config" "Fuzzel binding"
assert_contains 'spawn "ghostty"' "$niri_config" "Ghostty binding"
assert_contains 'focus-workspace 1' "$niri_config" "workspace binding"
assert_not_contains 'noctalia' "$niri_config" "Noctalia removed"
assert_not_contains 'hyprctl' "$niri_config" "Hyprland command removed"
assert_not_contains 'output "' "$niri_config" "fixed outputs removed"
assert_not_contains 'itterum-shell' "$niri_config" "Itterum Shell deferred"

for path in \
  hosts/desktop/default.nix \
  profiles/nixos/workstation.nix \
  profiles/home/workstation.nix \
  modules/home/desktop/niri/default.nix \
  itterum-shell/flake.nix; do
  assert_file_exists "${repo_root}/${path}"
done
for path in configuration.nix home.nix helix.nix; do
  assert_path_absent "${repo_root}/${path}"
done
flake_inputs=$(nix flake metadata "$flake_ref" --json | jq -c '.locks.nodes.root.inputs')
assert_not_contains 'nixos-wsl' "$flake_inputs" "NixOS-WSL input removed"
assert_not_contains 'noctalia' "$flake_inputs" "Noctalia input removed"

printf 'configuration regression checks passed\n'
