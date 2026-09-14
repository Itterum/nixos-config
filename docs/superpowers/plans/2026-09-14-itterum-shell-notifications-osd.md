# Itterum Shell Notifications and OSD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Mako and external Omarchy feedback helpers with the shell's notification server and native in-process OSD.

**Architecture:** Quickshell owns notification protocol state and transient OSD presentation. Notification window focusing goes through the compositor facade; volume and brightness producers emit typed internal events. NixOS/Home Manager ensure there is one notification owner and declare all required tools.

**Tech Stack:** Quickshell notification server, QML, compositor facade, PipeWire, brightnessctl, Home Manager, Bash/Node tests.

**Spec:** `docs/superpowers/specs/2026-09-14-hyprland-itterum-shell-design.md`

## Global Constraints

- Complete the foundation and appearance/applications/Arc Dock plans first.
- Do not introduce a public shell IPC/CLI merely to display OSD.
- Do not let Mako and Itterum Shell own the notification protocol concurrently.
- Missing notification metadata or compositor state must not crash the shell.

---

## Task 1: Make notifications self-contained

**Files:**

- Modify: `itterum-shell/shell/plugins/notifications/Service.qml`
- Modify: notification popup/history QML under `itterum-shell/shell/plugins/notifications/`
- Modify: `itterum-shell/shell/services/compositor/Compositor.qml`
- Modify: `itterum-shell/shell/services/compositor/HyprlandBackend.qml`
- Create: `itterum-shell/test/js/notification-model.test.mjs`
- Create: `itterum-shell/test/shell.d/notification-boundary.bash`

- [ ] Add model tests for replacement IDs, expiry, urgency, actions, dismissed history, missing icons, and missing app metadata.
- [ ] Add a boundary test rejecting `omarchy-*`, external notification daemons, and direct Hyprland access in notification UI.
- [ ] Run tests and confirm the current focus helper violates the boundary.
- [ ] Keep protocol ownership inside Quickshell. Normalize incoming notifications into a stable model and make expiry deterministic.
- [ ] Resolve a notification's matching window from facade state and call facade window focus. If no match exists, leave the notification usable without claiming focus succeeded.
- [ ] Ensure popup rendering and history tolerate absent images, actions, and application names.
- [ ] Connect the adapted Arc Dock badge counter to the normalized notification stream without giving the dock separate protocol ownership.
- [ ] Run focused notification tests and commit inside the submodule: `git add shell test && git commit -m "feat: internalize shell notifications"`.

## Task 2: Add native OSD events and presentation

**Files:**

- Modify: OSD QML under `itterum-shell/shell/plugins/osd/`
- Create: `itterum-shell/shell/services/Osd.qml`
- Modify: `itterum-shell/shell/services/AppLibrary.qml`
- Create: `itterum-shell/test/js/osd-state.test.mjs`
- Create: `itterum-shell/test/shell.d/osd-boundary.bash`

- [ ] Add state-machine tests for volume, mute, brightness, application launch, timeout replacement, and repeated updates.
- [ ] Add a static test rejecting `omarchy-shell`, socket dispatchers, and public helper commands in OSD producers.
- [ ] Run tests and confirm the existing launch-feedback invocation fails.
- [ ] Implement a singleton `Osd` service with typed methods/signals. New events replace the visible payload and restart one hide timer.
- [ ] Connect audio and brightness observations to `Osd`; emit launch feedback directly from `AppLibrary`.
- [ ] Keep OSD unavailable-state explicit and silent when a producer capability is absent.
- [ ] Run focused OSD tests and commit inside the submodule: `git add shell test && git commit -m "feat: add in-process shell OSD"`.

## Task 3: Activate and verify protocol ownership

**Files:**

- Modify: `modules/home/desktop/itterum-shell.nix`
- Modify: `modules/home/desktop/fallback.nix`
- Modify: `tests/configuration.sh`
- Create: `docs/testing/notifications-osd.md`

- [ ] Extend parent evaluation tests to assert Mako is disabled whenever the Itterum Shell notification plugin is enabled.
- [ ] Add negative evaluation assertions for an `omarchy-shell` package or command dependency.
- [ ] Run `bash tests/configuration.sh` and confirm the assertions fail before the integration edit.
- [ ] Declare only the standard runtime dependencies needed for volume and brightness signals. Do not add a general Omarchy compatibility package.
- [ ] Build the full NixOS toplevel and run all notification/OSD focused tests.
- [ ] In a graphical test session, send normal, critical, actionable, and replacement notifications; change volume/brightness; launch an app; verify placement, timing, and focus behavior.
- [ ] Inspect the user journal for `org.freedesktop.Notifications` ownership conflicts and repeated errors.
- [ ] Record screenshots at representative scaling and commit parent changes: `git add modules tests docs/testing/notifications-osd.md itterum-shell && git commit -m "feat: activate shell notifications and OSD"`.
