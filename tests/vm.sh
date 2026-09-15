#!/usr/bin/env bash

set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
flake_ref="path:${repo_root}#nixosConfigurations.desktop.config"

fail() { printf 'not ok - %s\n' "$1" >&2; exit 1; }
pass() { printf 'ok - %s\n' "$1"; }

eval_json() {
  nix eval --json "${flake_ref}.$1"
}

eval_raw() {
  nix eval --raw "${flake_ref}.$1"
}

[[ $(eval_json virtualisation.vmVariant.virtualisation.memorySize) == 8192 ]] \
  || fail "VM has 8 GiB of memory"
[[ $(eval_json virtualisation.vmVariant.virtualisation.cores) == 4 ]] \
  || fail "VM has four CPU cores"
[[ $(eval_json virtualisation.vmVariant.virtualisation.diskSize) == 32768 ]] \
  || fail "VM has a 32 GiB persistent disk"
[[ $(eval_json virtualisation.vmVariant.virtualisation.graphics) == true ]] \
  || fail "VM opens a graphics window"
pass "VM has usable desktop resources"

qemu_options=$(eval_json virtualisation.vmVariant.virtualisation.qemu.options)
jq -e 'index("-vga none") != null' <<<"$qemu_options" >/dev/null \
  || fail "VM disables the legacy VGA device"
jq -e 'index("-device virtio-vga") != null' <<<"$qemu_options" >/dev/null \
  || fail "VM exposes a compatible VirtIO graphics device"
jq -e 'index("-display gtk,gl=off,grab-on-hover=on") != null' <<<"$qemu_options" >/dev/null \
  || fail "VM avoids the broken host GTK OpenGL context and captures guest shortcuts"
[[ $(eval_raw virtualisation.vmVariant.environment.sessionVariables.LIBGL_ALWAYS_SOFTWARE) == 1 ]] \
  || fail "VM forces Mesa software rendering"
[[ $(eval_raw virtualisation.vmVariant.environment.sessionVariables.WLR_RENDERER_ALLOW_SOFTWARE) == 1 ]] \
  || fail "VM allows a software Wayland renderer"
pass "VM uses host-compatible software graphics"

[[ $(eval_raw virtualisation.vmVariant.services.greetd.settings.initial_session.user) == itterum ]] \
  || fail "VM autologin uses the workstation user"
initial_command=$(eval_raw virtualisation.vmVariant.services.greetd.settings.initial_session.command)
[[ $initial_command == *"uwsm start"* && $initial_command == *"hyprland.desktop"* ]] \
  || fail "VM autologin starts the Hyprland UWSM session"
[[ $(eval_raw virtualisation.vmVariant.users.users.itterum.initialPassword) == itterum ]] \
  || fail "VM has a recovery login password"
pass "VM boots directly into the Hyprland session"

physical_greetd=$(eval_json services.greetd.settings)
jq -e 'has("initial_session") | not' <<<"$physical_greetd" >/dev/null \
  || fail "physical configuration unexpectedly enables autologin"
physical_user=$(eval_json users.users.itterum)
jq -e '.initialPassword == null' <<<"$physical_user" >/dev/null \
  || fail "physical configuration unexpectedly contains the VM password"
pass "VM-only login settings do not leak into the physical configuration"

git -C "$repo_root" check-ignore -q result \
  || fail "Nix build result links are ignored"
git -C "$repo_root" check-ignore -q desktop.qcow2 \
  || fail "persistent VM disks are ignored"
pass "generated VM artifacts stay out of Git"
