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

assert_occurrences() {
  local expected=$1
  local needle=$2
  local haystack=$3
  local label=$4
  local remainder=$haystack
  local actual=0

  while [[ "$remainder" == *"$needle"* ]]; do
    remainder=${remainder#*"$needle"}
    ((actual += 1))
  done

  assert_eq "$expected" "$actual" "$label"
}

assert_file_exists() {
  local path=$1

  if [[ ! -f "$path" ]]; then
    printf 'expected file to exist: %s\n' "$path" >&2
    return 1
  fi
}

assert_path_absent() {
  local path=$1

  if [[ -e "$path" ]]; then
    printf 'expected path to be absent: %s\n' "$path" >&2
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

assert_file_exists "${repo_root}/profiles/nixos/workstation.nix"
assert_file_exists "${repo_root}/profiles/home/workstation.nix"
assert_file_exists "${repo_root}/modules/nixos/desktop/greeter.nix"
assert_file_exists "${repo_root}/modules/nixos/desktop/lock.nix"
assert_file_exists "${repo_root}/modules/home/desktop/niri/default.nix"
assert_file_exists "${repo_root}/modules/home/desktop/niri/startup.nix"
assert_file_exists "${repo_root}/modules/home/programs/helix/default.nix"
assert_file_exists "${repo_root}/experiments/itterum-shell/shell.qml"

assert_path_absent "${repo_root}/modules/profiles"
assert_path_absent "${repo_root}/modules/desktop"
assert_path_absent "${repo_root}/home/itterum/desktop.nix"
assert_path_absent "${repo_root}/home/itterum/files/niri/config.kdl"
assert_path_absent "${repo_root}/experimentals"

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

for host in laptop desktop; do
  assert_eq "false" "$(flake_json "$host" programs.dms-shell.enable)" "$host DMS disabled"
  assert_eq \
    "false" \
    "$(flake_json "$host" services.displayManager.dms-greeter.enable)" \
    "$host DMS greeter disabled"
  assert_eq "true" "$(flake_json "$host" services.greetd.enable)" "$host greetd"
  assert_eq \
    "true" \
    "$(flake_json "$host" services.greetd.useTextGreeter)" \
    "$host fallback text greeter"

  assert_eq \
    '"itterum"' \
    "$(flake_json "$host" services.greetd.settings.initial_session.user)" \
    "$host autologin user"
  assert_eq "false" "$(flake_json "$host" services.greetd.restart)" "$host autologin restart"
  autologin_command=$(flake_value "$host" services.greetd.settings.initial_session.command)
  assert_contains "niri-session" "$autologin_command" "$host autologin Niri command"

  fallback_command=$(flake_value "$host" services.greetd.settings.default_session.command)
  assert_contains "tuigreet" "$fallback_command" "$host fallback tuigreet"
  assert_contains "niri-session" "$fallback_command" "$host fallback Niri command"
  assert_not_contains "cage" "$fallback_command" "$host no Cage greeter"
  assert_not_contains "gtkgreet" "$fallback_command" "$host no GTK greeter"

  assert_eq "true" "$(flake_json "$host" programs.gtklock.enable)" "$host gtklock"
  assert_eq \
    "true" \
    "$(flake_json "$host" security.pam.services.gtklock.enableGnomeKeyring)" \
    "$host gtklock GNOME Keyring"
  gtklock_pam_source=$(nix build \
    --no-link \
    --print-out-paths \
    "${flake_ref}#nixosConfigurations.${host}.config.environment.etc.\"pam.d/gtklock\".source")
  gtklock_pam_auth=$(awk '/^# Authentication management\./,/^# Password management\./' "$gtklock_pam_source")
  assert_contains \
    "pam_gnome_keyring.so auto_start" \
    "$gtklock_pam_auth" \
    "$host gtklock unlocks GNOME Keyring during authentication"
  assert_contains \
    "nix-wallpaper.png" \
    "$(flake_value "$host" programs.gtklock.style)" \
    "$host gtklock wallpaper"

  home_prefix="home-manager.users.itterum"
  assert_eq "true" "$(flake_json "$host" "$home_prefix.programs.fuzzel.enable")" "$host Fuzzel"
  assert_eq "true" "$(flake_json "$host" "$home_prefix.services.swayidle.enable")" "$host swayidle"
  assert_contains \
    "gtklock --daemonize" \
    "$(flake_value "$host" "$home_prefix.services.swayidle.events.lock")" \
    "$host swayidle lock command"
  assert_eq "false" "$(flake_json "$host" "$home_prefix.programs.swaylock.enable")" "$host swaylock disabled"
  assert_eq "true" "$(flake_json "$host" "$home_prefix.services.wayle.enable")" "$host Wayle"
  assert_eq "false" "$(flake_json "$host" "$home_prefix.services.mako.enable")" "$host Mako disabled"
  assert_eq \
    '"Papirus-Dark"' \
    "$(flake_json "$host" "$home_prefix.gtk.iconTheme.name")" \
    "$host icon theme"
  assert_eq \
    '"macOS"' \
    "$(flake_json "$host" "$home_prefix.home.pointerCursor.name")" \
    "$host cursor theme"
done

helix_languages=$(flake_json laptop "home-manager.users.itterum.programs.helix.languages.language")
assert_eq \
  "true" \
  "$(flake_json laptop "home-manager.users.itterum.programs.helix.enable")" \
  "laptop Helix"
for language in typescript tsx javascript jsx rust python c-sharp nix qml json toml markdown bash kdl; do
  assert_occurrences \
    "1" \
    "\"name\":\"${language}\"" \
    "$helix_languages" \
    "Helix ${language} language"
done

home_files=$(flake_json laptop "home-manager.users.itterum.home.file")
assert_contains \
  'Pictures/Wallpapers/nix-wallpaper.png' \
  "$home_files" \
  "managed wallpaper"

niri_config=$(flake_value laptop "home-manager.users.itterum.programs.niri.finalConfig")
assert_contains \
  "niri-unstable" \
  "$(flake_value laptop programs.niri.package)" \
  "Niri build with SHM screencast support"
assert_eq \
  "true" \
  "$(flake_json laptop "home-manager.users.itterum.xdg.configFile.niri-config.force")" \
  "Niri config migration"
assert_contains 'output "HDMI-A-1"' "$niri_config" "Niri HDMI output"
assert_contains 'spawn "fuzzel"' "$niri_config" "Niri Fuzzel binding"
assert_contains 'spawn-at-startup "/nix/store/' "$niri_config" "Niri startup command"
assert_contains '/bin/gtklock"' "$niri_config" "Niri startup lock"
assert_contains 'spawn "gtklock" "--daemonize"' "$niri_config" "Niri gtklock binding"
assert_not_contains 'swaylock' "$niri_config" "Niri swaylock binding removed"
assert_contains 'focus-workspace 1' "$niri_config" "Niri workspace binding"
assert_contains \
  'move-column-to-monitor-left' \
  "$niri_config" \
  "Niri monitor binding"
assert_contains 'screenshot-window' "$niri_config" "Niri screenshot binding"
assert_contains 'Mod+Shift+S' "$niri_config" "Niri Gradia shortcut"
assert_contains '/bin/gradia-screenshot' "$niri_config" "Niri Gradia screenshot command"
assert_contains 'Mod+Alt+R' "$niri_config" "Niri Kooha shortcut"
assert_contains 'spawn "kooha"' "$niri_config" "Niri Kooha command"
assert_not_contains 'makoctl' "$niri_config" "Niri Mako bindings"
assert_not_contains 'include "dms/' "$niri_config" "Niri DMS includes"

printf 'configuration regression checks passed\n'
