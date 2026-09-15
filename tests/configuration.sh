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
assert_eq "true" "$(flake_json desktop programs.hyprland.enable)" "Hyprland"
assert_eq "true" "$(flake_json desktop programs.hyprland.withUWSM)" "Hyprland UWSM"
assert_eq '"hyprland-uwsm"' "$(flake_json desktop services.displayManager.defaultSession)" "default session"
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
for program in zsh starship direnv git helix foot zellij zed-editor; do
  assert_eq "true" "$(flake_json desktop ${home_prefix}.programs.${program}.enable)" "$program"
done
assert_eq \
  "true" \
  "$(flake_json desktop ${home_prefix}.programs.direnv.nix-direnv.enable)" \
  "nix-direnv"
home_packages=$(flake_json desktop ${home_prefix}.home.packages)
for package in ripgrep fd jq tree uv kubectl k9s codex chatgpt-linux nautilus gnome-disk-utility telegram-desktop obsidian bruno brave google-chrome xwayland-satellite; do
  assert_contains "$package" "$home_packages" "$package package"
done
for program in ghostty firefox; do
  assert_eq "false" "$(flake_json desktop ${home_prefix}.programs.${program}.enable)" "$program disabled"
done

assert_eq "false" "$(flake_json desktop ${home_prefix}.programs.waybar.enable)" "Waybar autostart disabled"
assert_eq "false" "$(flake_json desktop ${home_prefix}.services.mako.enable)" "Mako disabled"

shell_service="${home_prefix}.systemd.user.services.itterum-shell"
assert_contains \
  '"graphical-session.target"' \
  "$(flake_json desktop ${shell_service}.Unit.After)" \
  "Itterum Shell graphical ordering"
assert_contains \
  '"graphical-session.target"' \
  "$(flake_json desktop ${shell_service}.Unit.PartOf)" \
  "Itterum Shell graphical lifecycle"
assert_contains \
  '"graphical-session.target"' \
  "$(flake_json desktop ${shell_service}.Install.WantedBy)" \
  "Itterum Shell user service"
assert_eq '"on-failure"' "$(flake_json desktop ${shell_service}.Service.Restart)" "shell restart policy"
assert_eq '"3s"' "$(flake_json desktop ${shell_service}.Service.RestartSec)" "shell restart delay"
assert_eq "5" "$(flake_json desktop ${shell_service}.Unit.StartLimitBurst)" "shell restart burst"
assert_eq "60" "$(flake_json desktop ${shell_service}.Unit.StartLimitIntervalSec)" "shell restart interval"
assert_contains \
  'itterum-shell' \
  "$(flake_json desktop ${shell_service}.Service.ExecStart)" \
  "packaged shell executable"

hypr_files=$(flake_json desktop ${home_prefix}.xdg.configFile)
hypr_binds=$(jq -r '."hypr/bindings.lua".text' <<<"$hypr_files")
for action in foot itterum-shell loginctl; do
  assert_contains "$action" "$hypr_binds" "Hyprland rescue binding: $action"
done

hyprland_package=$(nix build --no-link --print-out-paths "${flake_ref}#nixosConfigurations.desktop.pkgs.hyprland^out")
hypr_config_home=$(mktemp -d)
trap 'rm -rf "$hypr_config_home"' EXIT
mkdir -p "$hypr_config_home/hypr"
for module in hyprland monitors input bindings looknfeel autostart; do
  jq -r --arg path "hypr/${module}.lua" '.[$path].text' <<<"$hypr_files" \
    >"$hypr_config_home/hypr/${module}.lua"
done
XDG_CONFIG_HOME="$hypr_config_home" \
  "${hyprland_package}/bin/Hyprland" --verify-config --config "$hypr_config_home/hypr/hyprland.lua" \
  || { printf 'generated Hyprland config is rejected by Hyprland\n' >&2; exit 1; }

assert_not_contains \
  './niri' \
  "$(<"${repo_root}/modules/home/desktop/default.nix")" \
  "Home Manager Niri inactive"

for path in \
  hosts/desktop/default.nix \
  profiles/nixos/workstation.nix \
  profiles/home/workstation.nix \
  modules/home/desktop/hyprland/default.nix \
  modules/home/desktop/hyprland/hyprland.lua \
  modules/home/desktop/hyprland/bindings.lua \
  modules/home/desktop/itterum-shell.nix \
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
