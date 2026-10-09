# KDE Plasma Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace GNOME/GDM on the `pc` profile with standard KDE Plasma 6 on Wayland through SDDM, using Foot instead of Ptyxis or Konsole.

**Architecture:** A focused `pcKde` NixOS module owns the desktop environment, display manager, and terminal choice. The host imports that module while all GNOME-specific Home Manager modules and packages are removed. The completed closure is installed for the next boot without interrupting the active GNOME session.

**Tech Stack:** NixOS 26.05 modules, flake-parts/import-tree, Home Manager, KDE Plasma 6, SDDM Wayland, Foot

**Spec:** `docs/superpowers/specs/2026-10-09-kde-migration-design.md`

## Global Constraints

- Work only on `codex/kde-migration`; do not modify `main`.
- Remove GNOME and GDM completely rather than retaining alternative sessions.
- Keep Plasma's standard layout; do not add `plasma-manager` or custom widgets.
- Keep NVIDIA, Sunshine, Steam, Docker, Flatpak, browsers, editors, IDE tooling, storage, SSH, and Codex configuration unchanged.
- Preserve `services.xserver.xkb.options = "ctrl:nocaps"`.
- Use Foot as the configured terminal and exclude Konsole.
- Activate with `nixos-rebuild boot`, not `switch`, so the current graphical session remains intact.

## Review Focus

- Display-manager exclusivity: evaluated config must enable SDDM and disable GDM.
- Session correctness: evaluated config must enable Plasma 6 and select the `plasma` Wayland session.
- Terminal exclusivity: Foot must exist while both Ptyxis and Konsole are absent from the final system package set.
- GNOME cleanup: no active module import or remaining repository file may reference the removed GNOME home module.
- Existing workstation behavior: the complete `pc` closure must still build with NVIDIA, Sunshine, Steam, Docker, Flatpak, and Home Manager enabled.

---

### Task 1: Add the KDE desktop module and switch the host

**Files:**
- Create: `modules/hosts/pc/kde.nix`
- Modify: `modules/hosts/pc/configuration.nix:5-54`

**Interfaces:**
- Consumes: `pkgs.kdePackages.konsole` and the existing `pcConfig` module composition.
- Produces: `flake.nixosModules.pcKde`, imported by `pcConfig`, with Plasma, SDDM Wayland, and Foot enabled.

- [ ] **Step 1: Run the failing desktop-state check**

Run:

```bash
test "$(nix eval --json .#nixosConfigurations.pc.config.services.desktopManager.plasma6.enable)" = true
```

Expected: FAIL because the current value is `false`.

- [ ] **Step 2: Create `flake.nixosModules.pcKde`**

In `modules/hosts/pc/kde.nix`, define a module that sets:

```nix
services.desktopManager.plasma6.enable = true;
services.displayManager.sddm.enable = true;
services.displayManager.sddm.wayland.enable = true;
services.displayManager.defaultSession = "plasma";
programs.foot.enable = true;
environment.plasma6.excludePackages = [ pkgs.kdePackages.konsole ];
```

- [ ] **Step 3: Include the untracked module in flake evaluation**

Run:

```bash
git add -N modules/hosts/pc/kde.nix
```

Expected: `import-tree` exposes `self.nixosModules.pcKde` without staging file contents for commit.

- [ ] **Step 4: Switch `pcConfig` to `pcKde`**

Add `self.nixosModules.pcKde` to the host imports. Remove `services.displayManager.gdm.enable` and `services.desktopManager.gnome.enable` from `configuration.nix`. Do not alter the XKB block or other host services.

- [ ] **Step 5: Run the desktop-state assertions**

Run a shell check that evaluates and asserts:

```text
services.desktopManager.plasma6.enable == true
services.displayManager.sddm.enable == true
services.displayManager.sddm.wayland.enable == true
services.displayManager.defaultSession == "plasma"
services.displayManager.gdm.enable == false
services.desktopManager.gnome.enable == false
programs.foot.enable == true
```

Expected: all assertions pass.

- [ ] **Step 6: Commit the desktop switch**

```bash
git add modules/hosts/pc/kde.nix modules/hosts/pc/configuration.nix
git commit -m "feat: switch pc desktop to KDE Plasma"
```

### Task 2: Remove GNOME configuration and replace Ptyxis

**Files:**
- Modify: `modules/hosts/pc/configuration.nix:22-31`
- Modify: `modules/hosts/pc/desktop-apps.nix:23-30`
- Delete: `modules/features/gnome.nix`
- Delete: `home/gnome/default.nix`
- Delete: `home/gnome/extensions.nix`
- Delete: `home/gnome/global-menu.nix`
- Delete: `home/gnome/settings.nix`

**Interfaces:**
- Consumes: `pcKde` from Task 1 as the sole desktop module.
- Produces: a host configuration with no GNOME Home Manager import, GNOME extension code, or Ptyxis package.

- [ ] **Step 1: Run the failing cleanup check**

Run:

```bash
if rg -n -i 'homeModules\.gnome|pkgs\.gnomeExtensions|ptyxis|global-menu-for-gnome' modules home; then
  exit 1
fi
```

Expected: FAIL and report the existing GNOME module/import and Ptyxis references.

- [ ] **Step 2: Remove active GNOME imports and packages**

Remove `self.homeModules.gnome` from `home-manager.users.itterum.imports` and remove `ptyxis` from `pcDesktopApps`. Preserve every other import and desktop application.

- [ ] **Step 3: Delete the GNOME-only modules**

Delete `modules/features/gnome.nix` and the complete `home/gnome/` directory. Git history remains the rollback source for these files.

- [ ] **Step 4: Run repository cleanup and terminal assertions**

Run checks that assert:

```text
the GNOME reference search from Step 1 returns no matches
programs.foot.enable == true
pkgs.ptyxis is absent from environment.systemPackages
pkgs.kdePackages.konsole is absent from environment.systemPackages
services.xserver.xkb.options == "ctrl:nocaps"
```

Expected: all assertions pass.

- [ ] **Step 5: Format and evaluate the flake**

Run:

```bash
nix fmt
git diff --check
nix flake show --no-write-lock-file
```

Expected: exit 0; `pcKde` appears under `nixosModules`, and `pc` evaluates.

- [ ] **Step 6: Commit GNOME cleanup**

```bash
git add modules/hosts/pc/configuration.nix modules/hosts/pc/desktop-apps.nix modules/features/gnome.nix home/gnome
git commit -m "refactor: remove GNOME desktop configuration"
```

### Task 3: Build and install the migration for next boot

**Files:**
- Verify only; no source changes expected.

**Interfaces:**
- Consumes: the complete `pc` configuration from Tasks 1 and 2.
- Produces: a built system closure and a bootloader entry that activates KDE Plasma after reboot.

- [ ] **Step 1: Run the full pre-boot configuration assertions**

Evaluate all Review Focus properties, plus:

```text
services.flatpak.enable == true
virtualisation.docker.enable == true
programs.steam.enable == true
services.sunshine.enable == true
services.xserver.videoDrivers contains "nvidia"
home-manager.users.itterum is defined
```

Expected: all assertions pass.

- [ ] **Step 2: Build the complete system closure**

Run:

```bash
nix build .#nixosConfigurations.pc.config.system.build.toplevel --no-link
```

Expected: exit 0 with a new `nixos-system-pc-26.05...` derivation.

- [ ] **Step 3: Install the generation for the next boot**

Run:

```bash
pkexec env PATH=/run/current-system/sw/bin:/usr/bin:/bin \
  nixos-rebuild boot --flake /home/itterum/nixos-config#pc
```

Expected: exit 0 and a new boot generation; the current GNOME session remains running.

- [ ] **Step 4: Verify the installed boot target and repository state**

Check that `/nix/var/nix/profiles/system` resolves to the newly built KDE closure, the running `/run/current-system` remains the prior generation, and `git status --short` is clean after commits.

- [ ] **Step 5: Record the pre-reboot handoff**

Report the branch and commit hashes, that `main` is unchanged, and that reboot is required. Provide the boot-menu rollback instruction and list the post-reboot checks from the design spec.

### Task 4: Verify KDE after reboot

**Files:**
- Verify only; source changes only if runtime evidence identifies a defect.

**Interfaces:**
- Consumes: the boot generation installed by Task 3.
- Produces: evidence that the migrated desktop is stable enough to merge into `main`.

- [ ] **Step 1: Confirm session and display manager**

Assert the active graphical session has `Type=wayland`, `Desktop=KDE`, and that `display-manager.service` resolves to SDDM.

- [ ] **Step 2: Confirm desktop processes and terminal**

Assert `plasmashell` and `kwin_wayland` are running, Foot launches, and neither GNOME Shell nor GDM is active.

- [ ] **Step 3: Verify NVIDIA rendering and inspect journals**

Confirm the NVIDIA driver is loaded and the active renderer is the NVIDIA GPU. Inspect the current boot journal for fatal SDDM, KWin, Plasma, Wayland, or NVIDIA errors.

- [ ] **Step 4: Verify retained workflows**

Launch or inspect Steam with GE-Proton, Docker, Flatpak/Bazaar, browsers, editors, and JetBrains Toolbox. Verify Sunshine accepts input/control from another machine on the local network.

- [ ] **Step 5: Decide integration**

If all checks pass, use `superpowers:finishing-a-development-branch` and let the user choose whether to merge `codex/kde-migration` into `main`. If a critical check fails, remain on the migration branch and fix it without changing `main`.
