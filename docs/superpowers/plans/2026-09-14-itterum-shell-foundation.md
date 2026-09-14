# Itterum Shell Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package the Omarchy-derived shell, make Hyprland the explicit workstation compositor, and deliver the core bar and installed-app launcher through a supervised Home Manager service.

**Architecture:** The `itterum-shell` submodule owns the immutable Quickshell package and compositor facade. The parent repository owns the NixOS Hyprland session, Home Manager service, generated user configuration, and application set. Ordinary UI code consumes `Compositor`; only `HyprlandBackend` may import `Quickshell.Hyprland` or call `hyprctl`.

**Tech Stack:** Nix flakes, NixOS 26.05, Home Manager, Hyprland/UWSM, Quickshell QML/JavaScript, Bash tests.

**Spec:** `docs/superpowers/specs/2026-09-14-hyprland-itterum-shell-design.md`

## Global Constraints

- Preserve the user's pre-existing edits in `modules/home/programs/apps.nix` and `tests/configuration.sh`; inspect and extend them instead of replacing them.
- Commit submodule changes inside `itterum-shell` first. Commit the updated submodule pointer from the parent only after the parent integration passes.
- Keep internal legacy plugin IDs when changing them would add risk, but expose only `itterum-shell` paths and names to users.
- Do not add an installer, package mutation, web-app provider, update action, public `omarchy` command, or public `ish` command.
- Do not set software-rendering environment variables in the installed launcher.
- Keep Niri modules buildable but inactive for the `desktop` host.
- Keep a manual fallback path until Plan 4; do not run fallback protocol owners alongside Itterum Shell.

---

## Task 1: Make the submodule an installable package

**Files:**

- Modify: `itterum-shell/flake.nix`
- Modify: `itterum-shell/.gitignore`
- Delete: `itterum-shell/daemon/target/`
- Create: `itterum-shell/nix/package.nix`
- Create: `itterum-shell/bin/itterum-shell`
- Create: `itterum-shell/test/shell.d/package.bash`

- [ ] Add a failing package-shape test which builds `.#packages.x86_64-linux.default`, checks `$out/bin/itterum-shell`, and rejects `QT_QUICK_BACKEND=software`, `LIBGL_ALWAYS_SOFTWARE`, `/usr/share/omarchy`, and `OMARCHY_PATH` in the installed launcher.
- [ ] Run `cd itterum-shell && bash test/shell.d/package.bash`; confirm it fails because no package output exists.
- [ ] Add `daemon/target/` to `.gitignore` and remove only the tracked Rust build artifacts from Git. Do not delete user files outside that exact path.
- [ ] Implement `nix/package.nix` so the package installs `shell/` and the approved default config under `$out/share/itterum-shell/`, installs private helpers under `$out/libexec/itterum-shell/`, and wraps Quickshell as `$out/bin/itterum-shell`.
- [ ] Make the launcher export `ITTERUM_SHELL_PATH=$out/share/itterum-shell` and execute one foreground Quickshell process. It must forward all arguments and leave renderer selection to the session.
- [ ] Export `packages.${system}.default`, `packages.${system}.itterum-shell`, `apps.${system}.default`, and the existing development shell from `flake.nix`.
- [ ] Run `bash test/shell.d/package.bash` and `nix build --no-link .#packages.x86_64-linux.default`.
- [ ] Commit inside the submodule: `git add flake.nix .gitignore nix/package.nix bin/itterum-shell test/shell.d/package.bash daemon/target && git commit -m "build: package Itterum Shell"`.

## Task 2: Replace ambient Omarchy paths and define the approved plugin set

**Files:**

- Modify: `itterum-shell/shell/shell.qml`
- Modify: `itterum-shell/shell/services/Backend.qml`
- Create: `itterum-shell/config/itterum-shell/shell.json`
- Modify: `itterum-shell/shell/services/Config.qml`
- Create: `itterum-shell/test/shell.d/product-scope.bash`
- Modify/Delete: excluded plugin and menu-provider files identified by the test

- [ ] Add a failing scope test which scans installed/runtime sources and fails on writable config paths below `~/.config/omarchy`, an `OMARCHY_PATH` dependency, install/remove/lazy-install actions, web-app catalog providers, Arch/AUR update actions, and excluded first-party plugin manifests.
- [ ] In the same test, parse the shipped configuration and assert that the bar contains core workspace/window/clock widgets and that the tray is the final entry of the right section.
- [ ] Run `cd itterum-shell && bash test/shell.d/product-scope.bash`; record the specific forbidden surfaces it finds.
- [ ] Change shell resource discovery to require `ITTERUM_SHELL_PATH`, with the packaged resource directory as the immutable source. Use `${XDG_CONFIG_HOME:-$HOME/.config}/itterum-shell/` for optional user overrides and XDG state/cache locations for writable runtime state.
- [ ] Replace the default configuration with the approved MVP plugin allowlist. Exclude update, Dropbox, Tailscale, weather, speed-test, disk-speed-test, AI/agent, provisioning, and hardware-management plugins from the package or registry.
- [ ] Remove application install/removal and web-app menu actions from source, not just from visible defaults. Preserve launching through freedesktop desktop entries.
- [ ] Delete the unused Rust/Python dual-backend prototype once no live QML imports it. Do not leave two runtime state owners.
- [ ] Run `bash test/shell.d/product-scope.bash`, the existing focused shell test runner, and `nix build --no-link .#packages.x86_64-linux.default`.
- [ ] Commit inside the submodule: `git add -A && git commit -m "refactor: make shell runtime distribution independent"`.

## Task 3: Introduce the compositor facade and migrate core UI

**Files:**

- Create: `itterum-shell/shell/services/compositor/Compositor.qml`
- Create: `itterum-shell/shell/services/compositor/HyprlandBackend.qml`
- Create: `itterum-shell/shell/services/compositor/Types.qml`
- Modify: `itterum-shell/shell/plugins/bar/Bar.qml`
- Modify: `itterum-shell/shell/plugins/bar/widgets/Workspaces.qml`
- Modify: `itterum-shell/shell/plugins/bar/widgets/KeyboardLayout.qml`
- Modify: `itterum-shell/shell/Commons/Style.qml`
- Modify: `itterum-shell/shell/Ui/PopupCard.qml`
- Create: `itterum-shell/test/shell.d/compositor-boundary.bash`
- Create: `itterum-shell/test/js/hyprland-mapping.test.mjs`

- [ ] Add a boundary test that permits `Quickshell.Hyprland` and `hyprctl` only below `shell/services/compositor/` and fails on either token in ordinary UI files.
- [ ] Add table-driven mapping tests for focused output, workspace identity/occupancy/focus, active-window metadata, and keyboard layout updates from representative Hyprland events.
- [ ] Run both tests and confirm they fail on current direct imports and missing mapping code.
- [ ] Define stable facade state: `available`, `outputs`, `focusedOutputId`, `workspaces`, `focusedWorkspaceId`, `activeWindow`, and `keyboardLayout`. Define actions for workspace focus, window focus, keyboard-layout switching, output changes, and output power.
- [ ] Implement `HyprlandBackend` as the sole adapter to Quickshell's Hyprland objects. Put unavoidable reviewed `hyprctl` processes here and return explicit failure state rather than optimistic success.
- [ ] Migrate bar placement, popup placement, workspaces, active-window display, and keyboard layout to the facade. Remove their direct compositor imports and command execution.
- [ ] Run `bash test/shell.d/compositor-boundary.bash`, `node --test test/js/hyprland-mapping.test.mjs`, and the existing focused bar tests.
- [ ] Commit inside the submodule: `git add shell test && git commit -m "refactor: isolate Hyprland behind compositor facade"`.

## Task 4: Make the launcher installed-apps-only

**Files:**

- Modify: `itterum-shell/shell/services/AppLibrary.qml`
- Modify: launcher/menu QML files under `itterum-shell/shell/plugins/`
- Create: `itterum-shell/test/shell.d/launcher-scope.bash`
- Create: `itterum-shell/test/js/desktop-entry-filter.test.mjs`

- [ ] Add tests for desktop-entry filtering: allowlisted installed applications are listed, non-allowlisted and `NoDisplay`/hidden entries are excluded, duplicates are stable, and no result carries install/remove/web-app/catalog actions.
- [ ] Add a static test which fails if launcher or menu code invokes `omarchy-*`, package managers, or writes desktop entries.
- [ ] Run the new tests and confirm current `remove()` and helper invocations fail them.
- [ ] Reduce `AppLibrary` to `DesktopEntries.applications`, the Home Manager-generated desktop-ID allowlist, filtering, search, and launch. Launch with `uwsm-app -- gtk-launch <desktop-id>` or the equivalent packaged standard command.
- [ ] Remove delete/install affordances and their keyboard/context-menu paths. Keep session actions separate from application results.
- [ ] Route launch feedback to an internal shell signal; do not invoke a public shell CLI.
- [ ] Run the launcher tests plus the full focused shell test suite.
- [ ] Commit inside the submodule: `git add shell test && git commit -m "feat: limit launcher to installed applications"`.

## Task 5: Switch the workstation profile to Hyprland and supervise the shell

**Files:**

- Modify: `flake.nix`
- Create: `modules/nixos/desktop/hyprland.nix`
- Modify: `modules/nixos/desktop/session.nix`
- Modify: `modules/nixos/desktop/greeter.nix`
- Modify: `profiles/nixos/workstation.nix`
- Create: `modules/home/desktop/hyprland/default.nix`
- Create: `modules/home/desktop/hyprland/binds.nix`
- Create: `modules/home/desktop/itterum-shell.nix`
- Modify: `modules/home/desktop/default.nix`
- Modify: `profiles/home/workstation.nix`
- Modify: `tests/configuration.sh`

- [ ] Extend `tests/configuration.sh` without dropping the user's local assertions. Assert `programs.hyprland.enable`, UWSM integration, Hyprland greetd launch, inactive Niri in the desktop profile, the shell package, and one enabled user service.
- [ ] Assert service hardening and recovery: graphical-session ordering, `Restart=on-failure`, nonzero restart delay, and bounded `StartLimitBurst`/`StartLimitIntervalSec`.
- [ ] Run `bash tests/configuration.sh`; confirm the new assertions fail.
- [ ] Make the shell input follow the parent's `nixpkgs` input and consume its default package.
- [ ] Enable `programs.hyprland` with UWSM in a dedicated NixOS module. Make the compositor selection explicit in `profiles/nixos/workstation.nix`; retain but do not import the Niri activation module.
- [ ] Configure greetd to launch the verified Hyprland UWSM desktop/session entry. Confirm the exact desktop entry name from the evaluated package instead of guessing it.
- [ ] Add minimal declarative Hyprland config with rescue bindings for a terminal, launcher, shell restart, lock, and session exit. A shell failure must leave keyboard access to a terminal.
- [ ] Add `systemd.user.services.itterum-shell` in Home Manager. Start exactly one foreground process with the graphical session; use bounded restart settings and journal logging.
- [ ] Prevent Waybar and Mako from auto-starting when Itterum Shell is enabled. Keep fallback packages and a documented manual rescue command until Plan 4.
- [ ] Run `bash tests/configuration.sh` and `nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'`.
- [ ] Commit parent integration and submodule pointer: `git add flake.nix flake.lock modules profiles tests itterum-shell && git commit -m "feat: add Hyprland Itterum Shell session"`. Include only intended hunks from pre-existing dirty files.

## Task 6: Verify the core graphical milestone

**Files:**

- Create: `docs/testing/hyprland-shell-core.md`
- Modify: `README.md`

- [ ] Document how to build without switching: `nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'`.
- [ ] Document VM/test-machine activation, journal inspection, shell restart, and manual fallback startup. State that the host's current Omarchy session is not modified by a no-link build.
- [ ] Boot a disposable graphical VM or test machine and capture evidence for: Hyprland login, one bar, workspace switching, active-window changes, clock, rightmost tray, installed-app launch, and terminal rescue after killing the shell.
- [ ] Kill the shell once and verify one controlled systemd restart. Inspect `journalctl --user -u itterum-shell.service -b` for loops and protocol conflicts.
- [ ] Visually compare 100% and one scaled resolution against the Omarchy reference; record screenshots and any accepted differences in the testing document.
- [ ] Re-run the package test, product-scope test, compositor tests, launcher tests, `bash tests/configuration.sh`, and the complete no-link system build.
- [ ] Commit documentation: `git add README.md docs/testing/hyprland-shell-core.md && git commit -m "docs: verify core Itterum Shell session"`.
