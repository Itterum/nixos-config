# NixOS System Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace Plasma's Kickoff launcher with a pinned SCP Menu Reborn widget that uses the NixOS icon and exposes only the approved system entries and session actions.

**Architecture:** The existing KDE Home Manager module packages the QML plasmoid as an immutable Nix derivation and adds it to the user profile. `plasma-manager` owns the widget placement and KConfig values, while the existing global menu and bottom dock remain unchanged.

**Tech Stack:** NixOS 26.05, Home Manager, plasma-manager, KDE Plasma 6.6, SCP Menu Reborn

**Spec:** `docs/superpowers/specs/2026-10-09-nixos-system-menu-design.md`

## Global Constraints

- Pin SCP Menu Reborn to commit `0f90c0fabd171167c7bf5555cf8cbb12e98295fe` with hash `sha256-xISUYW8so3zZPy6JP+OKr9uuGgznLeCD3md3IeY5SSs=`.
- Install the widget declaratively under `share/plasma/plasmoids/org.kde.plasma.scpmr`; do not use KDE Store or mutable `~/.local` installation.
- Use `nix-snowflake` as the menu icon.
- Show only Info Center and System Settings as application entries.
- Enable Lock, Log Out, Restart, and Shut Down; explicitly disable Sleep and Hibernate.
- Preserve the global menu, system tray, clock, bottom dock, and its Dodge Windows behavior.

## Review Focus

- Package layout: the built profile must expose `share/plasma/plasmoids/org.kde.plasma.scpmr/metadata.json`, or Plasma cannot discover the widget.
- JSON encoding: `Apps/appList` and `General/sessionButtons` must decode to the exact approved arrays rather than a Nix-formatted string.
- Launcher replacement: the top panel must contain exactly one system-menu widget and no Kickoff widget.
- Session safety: destructive actions must use the widget's KDE session APIs and retain their native confirmation behavior.
- Plasma stability: activation must leave `plasma-plasmashell.service` active and the generated panel state must reference `org.kde.plasma.scpmr`.

---

### Task 1: Package and configure the NixOS system menu

**Files:**
- Modify: `home/kde/default.nix`
- Modify: `tests/kde-panels.sh`

**Interfaces:**
- Consumes: the existing `programs.plasma.panels` layout and Home Manager package profile.
- Produces: the `scp-menu-reborn` package and an `org.kde.plasma.scpmr` top-panel widget with deterministic KConfig values.

- [ ] **Step 1: Extend the failing panel test**

Update `tests/kde-panels.sh` to assert:

- `home.packages` contains a derivation whose package name is `scp-menu-reborn`;
- the top panel contains `org.kde.plasma.scpmr` and excludes `org.kde.plasma.kickoff`;
- `General/icon` equals `nix-snowflake`;
- decoded `Apps/appList` equals Info Center (`org.kde.kinfocenter.desktop`, `hwinfo`) followed by System Settings (`systemsettings.desktop`, `preferences-system`);
- decoded `General/sessionButtons` contains Restart, Shut Down, Lock, and Log Out enabled, with Sleep and Hibernate disabled;
- the global menu and unchanged bottom-dock assertions still pass.

- [ ] **Step 2: Run the test and verify RED**

Run: `bash tests/kde-panels.sh`

Expected: exit 1 because the top panel still contains Kickoff and has no SCP Menu widget package or configuration.

- [ ] **Step 3: Add the pinned plasmoid package**

In `home/kde/default.nix`, accept `pkgs`, define `scpMenuReborn` with `pkgs.fetchFromGitHub` using the pinned revision/hash, and package it with `pkgs.stdenvNoCC.mkDerivation`. Copy `metadata.json` and `contents/` into `$out/share/plasma/plasmoids/org.kde.plasma.scpmr`, then add the derivation to `home.packages`.

- [ ] **Step 4: Replace Kickoff with the configured system menu**

Replace the top-panel Kickoff string with a generic widget whose `name` is `org.kde.plasma.scpmr`. Set `config.General.icon`, `config.General.sessionButtons`, and `config.Apps.appList` using `builtins.toJSON` over the exact values in Step 1. Keep the existing global-menu, spacer, tray, clock, and bottom panel entries byte-for-byte equivalent.

- [ ] **Step 5: Run GREEN checks and full build**

Run:

```bash
bash tests/kde-panels.sh
nix fmt
git diff --check
nix build .#nixosConfigurations.pc.config.system.build.toplevel --no-link --print-out-paths
```

Expected: exit 0; the test reports the KDE panel assertions passed and the build prints a `nixos-system-pc` store path.

- [ ] **Step 6: Commit the system menu**

```bash
git add home/kde/default.nix tests/kde-panels.sh
git commit -m "feat: add NixOS system menu"
```

### Task 2: Activate and verify the Plasma widget

**Files:**
- Verify only; no source changes expected.

**Interfaces:**
- Consumes: the built system closure and generated plasma-manager panel script from Task 1.
- Produces: an active Plasma session using the new system menu and a synchronized remote feature branch.

- [ ] **Step 1: Switch to the built configuration**

Run:

```bash
pkexec env PATH=/run/current-system/sw/bin:/usr/bin:/bin \
  nixos-rebuild switch --flake /home/itterum/nixos-config/.worktrees/kde-migration#pc
```

Expected: exit 0 and the new store path becomes `/run/current-system`.

- [ ] **Step 2: Apply the generated panel layout**

Run: `/home/itterum/.local/share/plasma-manager/run_all.sh`

Expected: the panel desktop script runs once because its content hash changed.

- [ ] **Step 3: Verify runtime discovery and stability**

Assert that:

- `systemctl --user is-active plasma-plasmashell.service` returns `active`;
- the current user profile contains `share/plasma/plasmoids/org.kde.plasma.scpmr/metadata.json`;
- `~/.config/plasma-org.kde.plasma.desktop-appletsrc` references `plugin=org.kde.plasma.scpmr` and does not reference `plugin=org.kde.plasma.kickoff`;
- the current-boot Plasma journal contains no crash or failed widget-load entry for `org.kde.plasma.scpmr`.

- [ ] **Step 4: Run final verification**

Run the Task 1 test and full NixOS build again, then assert the worktree is clean.

Expected: all commands exit 0 and the built store path equals `/run/current-system`.

- [ ] **Step 5: Push the feature branch**

```bash
git push origin codex/kde-migration
```

Expected: `codex/kde-migration` equals `origin/codex/kde-migration` at the system-menu commit.
