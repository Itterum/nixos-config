# Itterum Shell Appearance, Applications, and Arc Dock Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Apply Kanagawa as the shared default appearance, declare the exact workstation application set, configure the approved dark Bibata cursor, and integrate an Itterum-native Arc Dock.

**Architecture:** A single Home Manager theme module exports the Kanagawa palette and toolkit choices to application-specific modules. The package set is an explicit Nix list. Arc Dock is vendored with attribution into `itterum-shell`, uses the existing compositor facade and app library, and keeps only non-installing user preferences/state.

**Tech Stack:** Nix/Home Manager, GTK/Qt/dconf, Hyprland, Foot, Helix, Zed, Zellij, Quickshell QML, freedesktop desktop entries.

**Spec:** `docs/superpowers/specs/2026-09-14-hyprland-itterum-shell-design.md`

## Global Constraints

- Complete the foundation plan first.
- Preserve the user's existing uncommitted changes in `modules/home/programs/apps.nix`; use patch staging for intended hunks.
- Do not install theme extensions from a running shell or mutate application databases.
- The repository is public. Do not commit or fetch the locally converted Cursor Concept 2 files without express redistribution permission from their author.
- Preserve Arc Dock's MIT license, upstream URL, version, and source commit.

---

## Task 1: Define the shared Kanagawa theme contract

**Files:**

- Create: `modules/home/desktop/themes/kanagawa.nix`
- Modify: `modules/home/desktop/theme.nix`
- Modify: `modules/home/desktop/hyprland/default.nix`
- Modify: `modules/home/desktop/itterum-shell.nix`
- Create: `tests/theme.sh`

- [ ] Add evaluation tests asserting the default theme name is `kanagawa`, dark color scheme is selected, the canonical palette contains the expected Kanagawa background `#1f1f28` and foreground `#dcd7ba`, and the shell receives the generated palette.
- [ ] Assert Hyprland borders, shell colors, and toolkit configuration reference the shared theme data rather than independent copied literals outside the theme module.
- [ ] Run `bash tests/theme.sh` and confirm it fails before the module exists.
- [ ] Define the palette and semantic roles once in `themes/kanagawa.nix`. Expose background, foreground, accent, muted, selection, and status colors to consumers.
- [ ] Configure GTK and Qt for coherent dark appearance. Use Kanagawa-specific configuration where supported and system dark fallback where it is not.
- [ ] Generate Itterum Shell theme data and Hyprland decoration colors from the same module.
- [ ] Run theme tests and the full Nix evaluation test; commit: `git add modules tests/theme.sh && git commit -m "feat: make Kanagawa the default theme"`.

## Task 2: Declare the exact application set and adaptive configuration

**Files:**

- Modify: `modules/home/programs/apps.nix`
- Create: `modules/home/programs/foot.nix`
- Create: `modules/home/programs/zed.nix`
- Modify: `modules/home/programs/helix/default.nix`
- Create: `modules/home/programs/zellij.nix` or modify the existing Zellij owner
- Create: `modules/home/programs/terminal-desktop-entries.nix`
- Modify: `profiles/home/workstation.nix`
- Create: `tests/applications.sh`

- [ ] Add evaluation tests for exactly these requested products: Helix, Zed, Foot, Codex CLI, Codex desktop app, Obsidian, Bruno, Nautilus/Files, GNOME Disks, Zellij, Telegram, Brave, and Google Chrome.
- [ ] Add negative assertions that the previous Omarchy default/recommended application catalog is not pulled in by this module.
- [ ] Verify the selected Nixpkgs attributes and desktop IDs. In particular, confirm that `pkgs.chatgpt` supplies the requested Codex desktop workflow and `x-scheme-handler/codex`; if it does not, package the official Codex desktop artifact with a fixed source and hash instead of silently substituting a different app.
- [ ] Run `bash tests/applications.sh` and confirm the initial missing packages fail it.
- [ ] Declare the packages in `apps.nix`; keep unfree allowance explicit for Google Chrome, Obsidian, and the desktop app as required by their metadata.
- [ ] Configure Foot, Helix, Zed, and Zellij from the shared Kanagawa contract. Configure GTK/Qt/Electron/Chromium apps to follow the system dark appearance where exact Kanagawa theming is unsupported, and document each fallback.
- [ ] Create freedesktop entries for terminal-only Helix, Codex CLI, and Zellij using fixed `foot` argument arrays. These entries launch installed programs and contain no installation logic.
- [ ] Generate the shell desktop-ID allowlist from this application module and evaluate that every requested GUI/terminal entry is discoverable while incidental dependency entries are excluded.
- [ ] Run application/theme tests and the complete no-link system build; commit intended hunks only: `git add -p modules/home/programs/apps.nix && git add modules/home/programs profiles tests/applications.sh && git commit -m "feat: declare workstation application set"`.

## Task 3: Package an approved redistributable cursor consistently

**Files:**

- Modify: `modules/home/desktop/theme.nix`
- Modify: `modules/home/desktop/hyprland/default.nix`
- Modify: `tests/theme.sh`
- Create: `docs/assets/cursor.md`

- [ ] Record the observed source facts: local theme ID `linux-cursor-light`, display name `Cursor Concept 2 Light Linux`, size 24, conversion from Jepri Creations' Windows theme, public repository status, and the publisher's no-redistribution terms.
- [ ] Do not copy the original or converted asset into Git and do not create an unattended download derivation for it. Exact reuse requires written redistribution permission from the author.
- [ ] Configure the user-approved `Bibata-Modern-Classic` from `pkgs.bibata-cursors`; do not substitute the white `Bibata-Modern-Ice` variant.
- [ ] Replace the current `apple-cursor` placeholder with `home.pointerCursor.package = pkgs.bibata-cursors`, name `Bibata-Modern-Classic`, and size 24, including GTK/X11 integration, Hyprland environment, and matching dconf values.
- [ ] Extend tests to assert one cursor name/size across all owners and that the package exists in the closure.
- [ ] Run `bash tests/theme.sh`, build the cursor derivation, and visually verify normal, text, link, resize, busy, and XWayland cursors.
- [ ] Commit the licensed package configuration and provenance note: `git add modules/home/desktop/theme.nix modules/home/desktop/hyprland/default.nix tests/theme.sh docs/assets/cursor.md && git commit -m "feat: configure workstation cursor"`.

## Task 4: Import Arc Dock with attribution and negative scope tests

**Files:**

- Create: `itterum-shell/shell/plugins/io.github.claudsondouglas.arcdock/`
- Create: `itterum-shell/shell/plugins/io.github.claudsondouglas.arcdock/UPSTREAM.md`
- Create: `itterum-shell/test/shell.d/arc-dock-scope.bash`
- Create: `itterum-shell/test/js/arc-dock-model.test.mjs`

- [ ] Import the clean upstream tree from `https://github.com/claudsondouglas/arc.dock.git` at commit `15b16df783b1fbb97d6a31088e6c09a14da1cf77`, excluding its nested `.git` directory and preview tooling not shipped at runtime.
- [ ] Preserve `LICENSE` and record upstream URL, version 0.3.0, commit, and local adaptation notes in `UPSTREAM.md`.
- [ ] Add model tests for grouping windows by app ID, stable desktop-entry matching, pin order, recents, focus cycling, closing, and missing desktop entries.
- [ ] Add a scope test rejecting `omarchy-menu`, `omarchy-shell`, `~/.config/omarchy`, `~/.local/state/omarchy`, web-app behavior, and direct compositor imports outside the backend.
- [ ] Run the tests and confirm the unmodified upstream source fails the scope boundary.
- [ ] Commit import and tests inside the submodule: `git add shell/plugins/io.github.claudsondouglas.arcdock test && git commit -m "vendor: import Arc Dock 0.3.0"`.

## Task 5: Adapt Arc Dock to Itterum services

**Files:**

- Modify: QML under `itterum-shell/shell/plugins/io.github.claudsondouglas.arcdock/`
- Modify: `itterum-shell/shell/services/compositor/Compositor.qml`
- Modify: `itterum-shell/shell/services/compositor/HyprlandBackend.qml`
- Modify: `itterum-shell/config/itterum-shell/shell.json`
- Create: `itterum-shell/config/itterum-shell/arc-dock.json`
- Modify: tests created in Task 4

- [ ] Change dock config/state namespaces to `$XDG_CONFIG_HOME/itterum-shell/arc-dock.json` and `$XDG_STATE_HOME/itterum-shell/arc-dock.json`.
- [ ] Make the launcher button call the internal installed-app launcher and make settings open through the in-process plugin host. Remove both CLI fallback paths.
- [ ] Replace direct Hyprland output/workspace/toplevel/focus/coverage/blur calls with the compositor facade. Extend the facade only with shell-level capabilities that are also meaningful for a future Niri backend.
- [ ] Remove web-app icon-radius settings and web-app-specific assumptions. Keep normal freedesktop application actions, pin/unpin, recents, and close actions; none changes the installed package set.
- [ ] Seed declarative defaults: `dockTheme = "theme"`, `magnifyScale = 111`, Kanagawa colors, and pinned Foot, Files, Zed, Codex desktop app, Obsidian, Brave, Google Chrome, Telegram, and Bruno. Treat later pin order as user state, not package installation.
- [ ] Connect notification badges to the shell notification service only when that service is present; the dock must run without badges before the notifications plan lands.
- [ ] Run Arc Dock, compositor-boundary, launcher-scope, and package tests. Commit inside the submodule: `git add shell config test && git commit -m "feat: adapt Arc Dock for Itterum Shell"`.

## Task 6: Integrate and visually verify appearance and dock

**Files:**

- Modify: `modules/home/desktop/itterum-shell.nix`
- Modify: `tests/configuration.sh`
- Create: `docs/testing/appearance-apps-dock.md`

- [ ] Add parent evaluation assertions for the Arc Dock plugin, declarative defaults, exact approved pinned defaults, absence of Omarchy command dependencies, and the Kanagawa/cursor contract.
- [ ] Update the shell package pointer and complete the no-link system build.
- [ ] In a graphical test session verify all requested apps appear in the launcher, terminal entries open in Foot, and no unrequested default/web apps appear.
- [ ] Verify Arc Dock startup, installed-app launch/focus/cycle/close, pin/reorder persistence, recents, settings, auto-hide modes, multi-output choice, blur, magnification 111%, and degradation when notification badges are unavailable.
- [ ] Visually inspect Kanagawa in the shell, Hyprland, Foot, Helix, Zed, Zellij, Files, Disks, Telegram, Obsidian, Bruno, Brave, Google Chrome, Codex CLI, and Codex desktop app. Document exact-theme versus toolkit-dark behavior.
- [ ] Capture cursor consistency across shell, GTK, Qt, Electron/Chromium, and XWayland surfaces.
- [ ] Run theme/application/dock tests, `bash tests/configuration.sh`, `git diff --check`, and the complete no-link build.
- [ ] Commit parent integration: `git add modules tests docs/testing/appearance-apps-dock.md itterum-shell && git commit -m "feat: integrate Kanagawa apps and Arc Dock"`.
