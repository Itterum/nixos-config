#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
flake="builtins.getFlake \"path:$root\""
wallpapers="$(nix eval --json --impure --expr "
  let
    pc = ($flake).nixosConfigurations.pc;
    user = pc.config.home-manager.users.itterum;
  in {
    desktop = if user.programs.plasma.workspace.wallpaper == null then null else toString user.programs.plasma.workspace.wallpaper;
    lockScreen = if user.programs.plasma.kscreenlocker.appearance.wallpaper == null then null else toString user.programs.plasma.kscreenlocker.appearance.wallpaper;
    sddmTheme = pc.config.services.displayManager.sddm.theme;
  }
")"

desktop="$(jq -r '.desktop // empty' <<<"$wallpapers")"
lock_screen="$(jq -r '.lockScreen // empty' <<<"$wallpapers")"
sddm_theme="$(jq -r '.sddmTheme // empty' <<<"$wallpapers")"

test -n "$desktop"
test "$desktop" = "$lock_screen"
case "$(basename "$desktop")" in
  *-nix-wallpaper.png) ;;
  *) exit 1 ;;
esac
nix-store --realise "$desktop" >/dev/null
test "$(sha256sum "$desktop" | cut -d' ' -f1)" = "06a381bd115716b5ff40b23bd0e2c021ca5b6e2507fe350c2bdef2a827d8fa62"

case "$sddm_theme" in
  /nix/store/*/share/sddm/themes/nixos-breeze) ;;
  *) exit 1 ;;
esac

sddm_store="${sddm_theme%%/share/*}"
system="$(nix build --no-link --print-out-paths "$root#nixosConfigurations.pc.config.system.build.toplevel")"
test -d "$sddm_store"
test -f "$sddm_theme/theme.conf"
sddm_background="$(sed -n 's/^background=//p' "$sddm_theme/theme.conf")"
test -f "$sddm_background"
test "$(sha256sum "$sddm_background" | cut -d' ' -f1)" = "$(sha256sum "$desktop" | cut -d' ' -f1)"

desktop_store="$(sed -E 's|^(/nix/store/[^/]+).*|\1|' <<<"$desktop")"
nix-store --query --requisites "$system" | grep -Fx "$desktop_store" >/dev/null

echo "KDE and SDDM wallpaper assertions passed"
