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
assert_file_exists "${repo_root}/modules/home/desktop/noctalia.nix"
assert_file_exists "${repo_root}/modules/home/desktop/niri/default.nix"
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
assert_eq "false" "$(flake_json laptop services.kanata.enable)" "laptop Kanata disabled"
assert_eq "true" "$(flake_json desktop services.kanata.enable)" "desktop Kanata"

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
  assert_eq \
    '"hm-backup"' \
    "$(flake_json "$host" home-manager.backupFileExtension)" \
    "$host Home Manager migration backups"
  assert_eq "false" "$(flake_json "$host" programs.dms-shell.enable)" "$host DMS disabled"
  assert_eq \
    "false" \
    "$(flake_json "$host" services.displayManager.dms-greeter.enable)" \
    "$host DMS greeter disabled"
  assert_eq \
    "true" \
    "$(flake_json "$host" programs.noctalia-greeter.enable)" \
    "$host Noctalia Greeter"
  assert_eq "true" "$(flake_json "$host" services.greetd.enable)" "$host greetd"
  assert_eq \
    "false" \
    "$(flake_json "$host" services.greetd.useTextGreeter)" \
    "$host graphical greeter"

  greetd_settings=$(flake_json "$host" services.greetd.settings)
  assert_not_contains '"initial_session"' "$greetd_settings" "$host autologin disabled"

  greeter_command=$(flake_value "$host" services.greetd.settings.default_session.command)
  assert_contains "noctalia-greeter-session" "$greeter_command" "$host Noctalia greeter command"
  assert_not_contains "tuigreet" "$greeter_command" "$host tuigreet removed"
  assert_eq \
    '"niri"' \
    "$(flake_json "$host" programs.noctalia-greeter.settings.session.default)" \
    "$host greeter default session"
  assert_eq \
    '"us,ru"' \
    "$(flake_json "$host" programs.noctalia-greeter.settings.keyboard.layout)" \
    "$host greeter keyboard layouts"

  assert_eq "false" "$(flake_json "$host" programs.gtklock.enable)" "$host gtklock disabled"

  home_prefix="home-manager.users.itterum"
  assert_eq "true" "$(flake_json "$host" "$home_prefix.programs.noctalia.enable")" "$host Noctalia"
  assert_eq \
    "true" \
    "$(flake_json "$host" "$home_prefix.programs.noctalia.systemd.enable")" \
    "$host Noctalia user service"
  assert_eq "false" "$(flake_json "$host" "$home_prefix.programs.fuzzel.enable")" "$host Fuzzel disabled"
  assert_eq "false" "$(flake_json "$host" "$home_prefix.programs.anyrun.enable")" "$host AnyRun disabled"
  assert_eq "false" "$(flake_json "$host" "$home_prefix.services.swayidle.enable")" "$host swayidle disabled"
  assert_eq "false" "$(flake_json "$host" "$home_prefix.programs.swaylock.enable")" "$host swaylock disabled"
  assert_eq "false" "$(flake_json "$host" "$home_prefix.services.wayle.enable")" "$host Wayle disabled"
  assert_eq "false" "$(flake_json "$host" "$home_prefix.services.mako.enable")" "$host Mako disabled"
  assert_eq \
    '"Noctalia"' \
    "$(flake_json "$host" "$home_prefix.programs.noctalia.settings.theme.builtin")" \
    "$host Noctalia theme"
  assert_eq \
    "true" \
    "$(flake_json "$host" "$home_prefix.programs.noctalia.settings.lockscreen.enabled")" \
    "$host Noctalia lock screen"
  assert_eq \
    "300" \
    "$(flake_json "$host" "$home_prefix.programs.noctalia.settings.idle.behavior.lock.timeout")" \
    "$host Noctalia idle lock"
  assert_eq \
    "600" \
    "$(flake_json "$host" "$home_prefix.programs.noctalia.settings.idle.behavior.screen-off.timeout")" \
    "$host Noctalia screen off"
  assert_contains \
    "nix-wallpaper.png" \
    "$(flake_value "$host" "$home_prefix.programs.noctalia.settings.wallpaper.default.path")" \
    "$host Noctalia wallpaper"
  home_packages=$(flake_json "$host" "$home_prefix.home.packages")
  assert_contains "playerctl" "$home_packages" "$host Niri media binding dependency"
  assert_contains "brightnessctl" "$home_packages" "$host Niri brightness binding dependency"
  assert_eq \
    '"adw-gtk3-dark"' \
    "$(flake_json "$host" "$home_prefix.gtk.theme.name")" \
    "$host GTK theme"
  assert_eq \
    '"WhiteSur-dark"' \
    "$(flake_json "$host" "$home_prefix.gtk.iconTheme.name")" \
    "$host icon theme"
  assert_eq \
    '"qtct"' \
    "$(flake_json "$host" "$home_prefix.qt.platformTheme.name")" \
    "$host Qt platform theme"
  assert_eq \
    '"adwaita-dark"' \
    "$(flake_json "$host" "$home_prefix.qt.style.name")" \
    "$host Qt style"
  assert_eq \
    '"WhiteSur-dark"' \
    "$(flake_json "$host" "$home_prefix.qt.qt5ctSettings.Appearance.icon_theme")" \
    "$host Qt 5 icon theme"
  assert_eq \
    '"WhiteSur-dark"' \
    "$(flake_json "$host" "$home_prefix.qt.qt6ctSettings.Appearance.icon_theme")" \
    "$host Qt 6 icon theme"
  assert_eq \
    '["Adwaita Dark"]' \
    "$(flake_json "$host" "$home_prefix.programs.ghostty.settings.theme")" \
    "$host Ghostty theme"
  assert_eq \
    "true" \
    "$(flake_json "$host" "$home_prefix.programs.starship.settings.add_newline")" \
    "$host managed Starship config"
  assert_eq \
    '"macOS"' \
    "$(flake_json "$host" "$home_prefix.home.pointerCursor.name")" \
    "$host cursor theme"
done

assert_eq \
  "1800" \
  "$(flake_json laptop "home-manager.users.itterum.programs.noctalia.settings.idle.behavior.suspend.timeout")" \
  "laptop Noctalia suspend timeout"
assert_contains \
  "systemctl suspend" \
  "$(flake_value laptop "home-manager.users.itterum.programs.noctalia.settings.idle.behavior.suspend.command")" \
  "laptop Noctalia suspend command"
assert_not_contains \
  '"suspend"' \
  "$(flake_json desktop "home-manager.users.itterum.programs.noctalia.settings.idle.behavior")" \
  "desktop Noctalia suspend disabled"

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
assert_contains \
  'spawn "noctalia" "msg" "panel-toggle" "launcher"' \
  "$niri_config" \
  "Niri Noctalia launcher binding"
assert_contains \
  'spawn "noctalia" "msg" "session" "lock"' \
  "$niri_config" \
  "Niri Noctalia lock binding"
assert_not_contains 'spawn-at-startup' "$niri_config" "Niri startup lock removed"
assert_not_contains 'gtklock' "$niri_config" "Niri gtklock binding removed"
assert_not_contains 'anyrun' "$niri_config" "Niri AnyRun binding removed"
assert_not_contains 'swaylock' "$niri_config" "Niri swaylock binding removed"
assert_contains 'focus-workspace 1' "$niri_config" "Niri workspace binding"
assert_contains \
  'move-column-to-monitor-left' \
  "$niri_config" \
  "Niri monitor binding"
assert_contains 'screenshot-window' "$niri_config" "Niri screenshot binding"
assert_not_contains 'makoctl' "$niri_config" "Niri Mako bindings"
assert_not_contains 'include "dms/' "$niri_config" "Niri DMS includes"

printf 'configuration regression checks passed\n'
