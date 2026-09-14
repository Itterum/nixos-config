#!/usr/bin/env bash

set -euo pipefail

root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
flake_ref="path:$root#nixosConfigurations.desktop.config.home-manager.users.itterum"

fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$1"; }

config_files=$(nix eval --json "$flake_ref.xdg.configFile")
spotlight=$(jq -r '."itterum-shell/spotlight.json".text // empty' <<<"$config_files")
[[ -n $spotlight ]] || fail "Spotlight configuration is managed by Home Manager"
jq -e '
  .fileSearch == true and
  .clipboardSearch == true and
  .learningEnabled == true and
  .maxResults == 20 and
  .maxApps == 8 and
  (.webSuggestions == null) and
  (.searchEngine == null)
' <<<"$spotlight" >/dev/null || fail "Spotlight has the approved local-only defaults"
pass "Spotlight local-only configuration is managed declaratively"

[[ $(nix eval --json "$flake_ref.services.cliphist.enable") == true ]] \
  || fail "Clipboard history service is enabled"
[[ $(nix eval --json "$flake_ref.services.cliphist.allowImages") == false ]] \
  || fail "Clipboard history stores text only"
pass "Spotlight clipboard history is enabled without image retention"

shell_json=$(jq -r '."itterum-shell/shell.json".text' <<<"$config_files")
jq -e '.plugins | any(.id == "io.github.maajix.spotlight")' <<<"$shell_json" >/dev/null \
  || fail "Spotlight is enabled"
pass "Spotlight is enabled declaratively"

hyprland=$(nix eval --json "$flake_ref.wayland.windowManager.hyprland.settings")
jq -e '.bind | any(test("ALT, Space.*io.github.maajix.spotlight"))' <<<"$hyprland" >/dev/null \
  || fail "Alt+Space opens Spotlight"
jq -e '.layerrule | any(test("blur.*itterum-spotlight"))' <<<"$hyprland" >/dev/null \
  || fail "Spotlight blur is declared"
pass "Spotlight Hyprland integration is declarative"

[[ -f $root/itterum-shell/shell/plugins/menu/Menu.qml ]] \
  || fail "The existing launcher remains packaged"
jq -e '.bind | any(test("SUPER, Space.*omarchy.menu"))' <<<"$hyprland" >/dev/null \
  || fail "The existing launcher keeps its key binding"
pass "The existing launcher remains available as fallback"
