# Itterum Shell System Panels Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver audio, network, Bluetooth, power, and monitor panels with declarative dependencies and safe capability degradation.

**Architecture:** Each panel consumes a narrow typed service. Typed Quickshell APIs are preferred; otherwise the package provides a feature-specific private adapter under `libexec/itterum-shell`. Monitor actions are exclusive to the compositor facade. The shell performs runtime actions but never persists Nix configuration.

**Tech Stack:** Quickshell/QML, PipeWire/WirePlumber, NetworkManager, BlueZ, UPower, power-profiles-daemon, logind, Hyprland facade, NixOS/Home Manager.

**Spec:** `docs/superpowers/specs/2026-09-14-hyprland-itterum-shell-design.md`

## Global Constraints

- Complete the foundation, appearance/applications/Arc Dock, and notifications/OSD plans first.
- Private adapters must have fixed argument contracts, structured output, no shell interpolation, and no general command-dispatch mode.
- A missing service, radio, battery, or power-profile provider disables only its widget/panel.
- Monitor changes affect the live session only; do not edit Hyprland or Nix files.

---

## Task 1: Audio panel through PipeWire

**Files:**

- Modify/Create: audio service and panel QML under `itterum-shell/shell/plugins/panels/audio/`
- Modify: `itterum-shell/shell/services/Osd.qml`
- Create: `itterum-shell/test/js/audio-model.test.mjs`
- Create: `itterum-shell/test/shell.d/audio-boundary.bash`

- [ ] Add tests for default sink/source, volume bounds, mute, device switching, stream movement, and PipeWire-unavailable state.
- [ ] Add a boundary test rejecting Omarchy audio helpers and unescaped shell command strings.
- [ ] Run the tests and confirm failure against current implementation.
- [ ] Bind the panel to Quickshell PipeWire objects. Clamp requested volume, expose explicit errors, and send volume/mute changes to the internal OSD.
- [ ] Hide device/stream actions that the current PipeWire state cannot support rather than inventing state.
- [ ] Run focused tests and commit: `git add shell test && git commit -m "feat: add PipeWire audio panel"`.

## Task 2: Network and Bluetooth panels

**Files:**

- Modify/Create: network service and panel QML under `itterum-shell/shell/plugins/panels/network/`
- Modify/Create: Bluetooth service and panel QML under `itterum-shell/shell/plugins/panels/bluetooth/`
- Create: private fixed-contract adapters under `itterum-shell/bin/libexec/` only if typed APIs are insufficient
- Create: `itterum-shell/test/fixtures/network/`
- Create: `itterum-shell/test/fixtures/bluetooth/`
- Create: `itterum-shell/test/js/network-model.test.mjs`
- Create: `itterum-shell/test/js/bluetooth-model.test.mjs`

- [ ] Add fixture-driven tests for NetworkManager disconnected/connected/scanning states, known Wi-Fi activation, password-required errors, and no Wi-Fi hardware.
- [ ] Add fixture-driven tests for BlueZ powered/off/unavailable, paired devices, connect/disconnect, and failed pairing.
- [ ] Add negative tests for Tailscale, speed tests, package installation, persistence edits, and arbitrary command execution.
- [ ] Implement network state/actions using NetworkManager APIs or fixed `nmcli` argument arrays. Never concatenate SSIDs or passwords into a shell command.
- [ ] Implement Bluetooth state/actions using BlueZ APIs or fixed `bluetoothctl` argument arrays. Keep pairing prompts bounded to the panel lifecycle.
- [ ] Package any required adapter privately and include only its standard runtime dependencies.
- [ ] Run focused tests with and without radios present; commit: `git add shell bin test && git commit -m "feat: add network and Bluetooth panels"`.

## Task 3: Power and session panel

**Files:**

- Modify/Create: power service and panel QML under `itterum-shell/shell/plugins/panels/power/`
- Create: `itterum-shell/test/js/power-model.test.mjs`
- Create: `itterum-shell/test/shell.d/power-boundary.bash`

- [ ] Add tests for AC-only systems, battery percentage/state, unavailable power profiles, profile switching, and confirmation state for destructive session actions.
- [ ] Add a boundary test allowing only logind/systemd actions and rejecting Omarchy power/hardware helpers.
- [ ] Implement battery state from UPower and profiles from power-profiles-daemon. Hide unsupported selectors while keeping suspend/session actions available.
- [ ] Route logout, suspend, reboot, and poweroff through reviewed logind/systemd commands with explicit failure reporting. Keep confirmation for reboot and poweroff.
- [ ] Run focused tests and commit: `git add shell test && git commit -m "feat: add power and session panel"`.

## Task 4: Monitor panel through the compositor facade

**Files:**

- Modify: `itterum-shell/shell/plugins/panels/monitor/Panel.qml`
- Modify: `itterum-shell/shell/services/compositor/Compositor.qml`
- Modify: `itterum-shell/shell/services/compositor/HyprlandBackend.qml`
- Modify: `itterum-shell/test/js/hyprland-mapping.test.mjs`
- Create: `itterum-shell/test/js/monitor-model.test.mjs`

- [ ] Add tests for output inventory, focused output, enable/disable guard, mode/scale/position validation, action failure, and unplug during an open panel.
- [ ] Assert the UI contains neither `hyprctl` nor `Quickshell.Hyprland`.
- [ ] Implement monitor UI against facade models/actions only. Prevent disabling the final active output and validate scale/mode before dispatch.
- [ ] Implement Hyprland-specific calls exclusively in `HyprlandBackend`; refresh state from compositor events after successful actions rather than mutating UI optimistically.
- [ ] Label live-session changes as temporary; do not offer a save-to-config action.
- [ ] Run compositor and monitor tests and commit: `git add shell test && git commit -m "feat: add compositor-backed monitor panel"`.

## Task 5: Declare capabilities and perform graphical acceptance

**Files:**

- Modify: relevant modules under `modules/nixos/desktop/` and `modules/nixos/services/`
- Modify: `modules/home/desktop/itterum-shell.nix`
- Modify: `tests/configuration.sh`
- Create: `docs/testing/system-panels.md`

- [ ] Add Nix evaluation assertions for PipeWire/WirePlumber, NetworkManager, BlueZ, UPower, power-profiles-daemon when selected, polkit, and exact private runtime tools.
- [ ] Assert excluded Tailscale/weather/speed-test dependencies and user-facing helper commands are absent.
- [ ] Enable required standard services declaratively and pass no mutable configuration path to the shell.
- [ ] Run every panel test, `bash tests/configuration.sh`, and the complete no-link NixOS build.
- [ ] In a graphical test session exercise every available panel, then test safe degradation by stopping or masking one capability at a time where safe.
- [ ] Verify tray remains the rightmost right-section item after adding widgets and record screenshots/log observations.
- [ ] Commit parent integration: `git add modules tests docs/testing/system-panels.md itterum-shell && git commit -m "feat: integrate shell system panels"`.
