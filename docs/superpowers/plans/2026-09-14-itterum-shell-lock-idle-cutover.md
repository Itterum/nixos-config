# Itterum Shell Lock, Idle, and Cutover Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish Wayland session lock and idle behavior, retire superseded fallback services, and verify the complete Hyprland-first desktop remains recoverable.

**Architecture:** The shell owns lock presentation and idle transitions; NixOS owns PAM and logind capabilities. Output power uses the compositor facade. Fallback programs remain optionally installed for rescue, but their services and key bindings do not compete with the normal shell session.

**Tech Stack:** Quickshell Wayland session lock/PAM, QML, systemd-logind, systemd user units, Hyprland facade, NixOS/Home Manager, graphical acceptance tests.

**Spec:** `docs/superpowers/specs/2026-09-14-hyprland-itterum-shell-design.md`

## Global Constraints

- Complete the preceding foundation, appearance/applications/Arc Dock, notifications/OSD, and system-panels plans first.
- Never test lock authentication using real passwords in logs, fixtures, or command arguments.
- A broken lock screen is a security and recovery failure; retain a controlled TTY/rescue route during testing.
- Disable fallback auto-start only after each replacement passes its acceptance check.

---

## Task 1: Implement session lock with PAM

**Files:**

- Modify: lock QML under `itterum-shell/shell/plugins/lock/`
- Modify: `itterum-shell/shell/services/compositor/Compositor.qml`
- Create: `itterum-shell/test/js/lock-state.test.mjs`
- Create: `itterum-shell/test/shell.d/lock-boundary.bash`
- Create: `modules/nixos/desktop/itterum-shell-lock.nix`
- Modify: `profiles/nixos/workstation.nix`

- [ ] Add state tests for unlocked/locking/locked/authenticating/error, failed authentication, cancel behavior, per-output surfaces, and output hotplug.
- [ ] Add a boundary test rejecting `swaylock`, Omarchy lock helpers, direct Hyprland access, and password-bearing command execution.
- [ ] Run tests and confirm the current lock integration fails the new boundary.
- [ ] Implement Wayland session-lock ownership in the shell and authenticate through the dedicated PAM service name `itterum-shell-lock`.
- [ ] Render a lock surface on every output and keep input focused safely across hotplug. Do not dismiss lock on backend or rendering errors.
- [ ] Add the minimal NixOS PAM declaration and no reusable secret material.
- [ ] Run evaluation and focused lock tests; commit submodule and parent changes separately with messages `feat: add shell session lock` and `feat: configure Itterum Shell PAM`.

## Task 2: Implement idle transitions and output power

**Files:**

- Modify: `itterum-shell/shell/plugins/services/idle/Service.qml`
- Modify: `itterum-shell/shell/services/compositor/Compositor.qml`
- Modify: `itterum-shell/shell/services/compositor/HyprlandBackend.qml`
- Create: `itterum-shell/test/js/idle-state.test.mjs`
- Modify: `modules/home/desktop/itterum-shell.nix`

- [ ] Add deterministic tests with short fake timers for dim, lock, output-off, wake, inhibit, and before-sleep transitions.
- [ ] Assert idle UI/service code has no direct Hyprland import or `hyprctl` call.
- [ ] Implement idle state from Quickshell idle/inhibit facilities. Request lock before output-off and before suspend; restore outputs through the facade on activity.
- [ ] Implement output power only in `HyprlandBackend`, returning failure state for disconnected outputs or unavailable IPC.
- [ ] Hook the graphical session's before-sleep/resume path to shell lock/wake without introducing a public command router.
- [ ] Run idle and compositor tests; commit: `git add shell test && git commit -m "feat: add shell idle management"`.

## Task 3: Retire competing fallback services

**Files:**

- Modify: `modules/home/desktop/fallback.nix`
- Modify: `modules/home/desktop/hyprland/binds.nix`
- Modify: `modules/home/desktop/itterum-shell.nix`
- Modify: `tests/configuration.sh`
- Create: `bin/start-desktop-fallback` or an equivalent private Home Manager script

- [ ] Add evaluation tests proving normal activation starts no Waybar, Mako, Fuzzel daemon, swaylock, or swayidle service/binding.
- [ ] Assert one owner for notifications, bar layer surfaces, lock, and idle behavior.
- [ ] Run `bash tests/configuration.sh` and confirm the new assertions fail before cutover.
- [ ] Disable superseded fallback services and replace normal bindings with Itterum Shell actions.
- [ ] Keep a narrowly documented rescue script or command that can start the fallback bar/launcher/lock from a terminal. It must not auto-start and must not modify Nix configuration.
- [ ] Ensure the rescue path can stop conflicting shell protocol owners before starting fallback components and can be reversed by restarting the user session.
- [ ] Run evaluation tests and the complete no-link build; commit: `git add modules tests bin && git commit -m "feat: complete shell fallback cutover"`.

## Task 4: Complete end-to-end acceptance and documentation

**Files:**

- Modify: `README.md`
- Create: `docs/testing/hyprland-shell-acceptance.md`
- Modify: `docs/testing/hyprland-shell-core.md`
- Modify: other testing notes created by preceding plans

- [ ] Build the shell package and full system from a clean Git view: `nix build --no-link 'path:./itterum-shell#packages.x86_64-linux.default'` and `nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'`.
- [ ] Run all submodule focused tests and `bash tests/configuration.sh`; record exact commands and results.
- [ ] Boot the graphical target and verify every spec acceptance item: login, Kanagawa/application adaptation, requested cursor, Arc Dock, bar/output count, workspaces, active window, keyboard layout, rightmost tray, installed-app launcher, notifications, OSD, five system panels, lock, idle, restart limits, and safe capability absence.
- [ ] Verify excluded product surfaces by searching the installed store output, desktop entries, launcher/menu UI, key bindings, and service units for installers, web apps, Arch/Omarchy updates, excluded integrations, and public `omarchy`/`ish` commands.
- [ ] Kill the shell repeatedly up to and beyond the configured burst limit. Confirm bounded recovery, no hot loop, usable rescue bindings, and a readable user journal.
- [ ] Capture visual evidence for bar, launcher, panels, notifications, OSD, and lock at representative resolutions/scales. Note deviations requiring a follow-up rather than silently accepting them.
- [ ] Update README with the Hyprland-first status, build-only command for the current Omarchy host, activation instructions, journal command, recovery path, and explicit Niri deferral.
- [ ] Confirm `git diff --check`, inspect both parent and submodule status, and ensure no generated result links, VM disks, screenshots outside their intended docs location, or credentials are staged.
- [ ] Commit final documentation: `git add README.md docs/testing && git commit -m "docs: record Hyprland shell acceptance"`.

## Task 5: Final review gate

**Files:**

- Review: all files changed by the four implementation plans

- [ ] Compare the implementation line-by-line with the approved spec and list any unmet item.
- [ ] Confirm all ordinary UI files are compositor-neutral and only `HyprlandBackend` contains Hyprland integration.
- [ ] Confirm persistent package/application/system settings have exactly one declarative owner.
- [ ] Confirm Niri code remains inactive but the facade contract is documented sufficiently for a later `NiriBackend`.
- [ ] Run the complete verification matrix once more after the final review fixes.
- [ ] Do not claim the milestone complete until every required graphical acceptance item has evidence; report hardware-only checks separately if the VM cannot exercise them.
