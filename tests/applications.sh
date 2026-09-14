#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
flake_ref="path:${repo_root}"
home_prefix="nixosConfigurations.desktop.config.home-manager.users.itterum"

eval_json() {
  nix eval --json "${flake_ref}#${home_prefix}.$1"
}

fail() { printf '%s\n' "$*" >&2; exit 1; }

expected_ids='["itterum-helix","dev.zed.Zed","foot","itterum-codex-cli","chatgpt","obsidian","bruno","org.gnome.Nautilus","org.gnome.DiskUtility","itterum-zellij","org.telegram.desktop","com.brave.Browser","com.google.Chrome"]'
actual_ids=$(eval_json itterum.applications.desktopIds)
[[ $actual_ids == "$expected_ids" ]] || fail "desktop allowlist mismatch: $actual_ids"

for program in helix foot zellij zed-editor; do
  [[ $(eval_json programs.${program}.enable) == true ]] || fail "$program is not enabled"
done

packages=$(eval_json home.packages)
for package in codex chatgpt-linux obsidian bruno nautilus gnome-disk-utility telegram-desktop brave google-chrome; do
  [[ $packages == *"$package"* ]] || fail "$package is missing"
done

for removed in firefox ghostty keepassxc; do
  [[ $packages != *"$removed"* ]] || fail "unrequested app remains: $removed"
done
[[ $(eval_json programs.firefox.enable) == false ]] || fail "Firefox remains enabled"
[[ $(eval_json programs.ghostty.enable) == false ]] || fail "Ghostty remains enabled"

entries=$(nix eval --json "${flake_ref}#${home_prefix}.xdg.desktopEntries" --apply builtins.attrNames)
for entry in itterum-helix itterum-codex-cli itterum-zellij; do
  jq -e --arg entry "$entry" 'index($entry) != null' <<<"$entries" >/dev/null || fail "missing desktop entry: $entry"
done

config_files=$(eval_json xdg.configFile)
shell_json=$(jq -r '."itterum-shell/shell.json".text' <<<"$config_files")
[[ $(jq -c '.applications' <<<"$shell_json") == "$expected_ids" ]] || fail "shell allowlist is not generated from applications module"

printf 'application regression checks passed\n'
