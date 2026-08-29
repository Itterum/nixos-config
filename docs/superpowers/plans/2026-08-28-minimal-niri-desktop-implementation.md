# Minimal Niri Desktop Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace DMS with greetd/tuigreet and a static, lightweight Niri desktop composed from Fuzzel, Mako, swayidle and swaylock.

**Architecture:** A NixOS session module owns greetd and tuigreet, while Home Manager owns user-facing programs, services and static Catppuccin configuration. The checked-in Niri KDL becomes self-contained so no runtime-generated DMS files are required.

**Tech Stack:** NixOS 26.05, Home Manager 26.05, greetd, tuigreet, Niri 26.04, Fuzzel 1.14.1, Mako 1.11.0, swayidle 1.9.0, swaylock 1.8.5.

**Spec:** `docs/superpowers/specs/2026-08-28-minimal-niri-desktop-design.md`

## Global Constraints

- Keep Catppuccin Mocha with the mauve accent.
- Keep Papirus-Dark icons and the `macOS` cursor at size 24.
- Preserve the current two-monitor layout and normal Niri window-management bindings.
- Do not activate the new NixOS generation or stop the current graphical session.
- Preserve unrelated uncommitted Helix, Zed and personal Quickshell files.
- Do not add Waybar, a wallpaper daemon or a dynamic theme generator.

---

### Task 1: Add migration regression assertions

**Files:**
- Modify: `tests/configuration.sh`

**Interfaces:**
- Consumes: both NixOS configurations, their embedded Home Manager user configuration and the checked-in Niri KDL.
- Produces: assertions covering the login stack, desktop components, theme identity and removal of DMS coupling.

- [x] **Step 1: Add failing assertions**

Assert for both hosts that DMS and the DMS greeter are disabled, greetd is
enabled with `useTextGreeter`, and its command contains both `tuigreet` and
`niri-session`. Assert that Home Manager enables Fuzzel, Mako, swayidle and
swaylock and selects Papirus-Dark and the macOS cursor. Assert textually that
the Niri source has no `include "dms/` line and contains the Fuzzel and
swaylock bindings.

- [x] **Step 2: Run the checks to verify RED**

Run: `bash tests/configuration.sh`

Expected: FAIL because the current configuration still enables DMS and its
greeter and does not enable the replacement components.

### Task 2: Replace the system login stack

**Files:**
- Create: `modules/desktop/session.nix`
- Modify: `modules/profiles/workstation.nix`
- Delete: `modules/desktop/dms.nix`

**Interfaces:**
- Consumes: `config.programs.niri.package` and `pkgs.tuigreet`.
- Produces: greetd configuration whose default session runs tuigreet and whose selected command starts `niri-session`.

- [x] **Step 1: Add the greetd/tuigreet module**

Enable greetd and its text-greeter mode. Set the default-session command to
`${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-user-session
--asterisks --cmd ${config.programs.niri.package}/bin/niri-session` and keep
the greeter user at the module default.

- [x] **Step 2: Change the workstation composition**

Replace the `dms.nix` import with `session.nix`, remove the obsolete DMS module,
and leave `programs.niri.enable = true` in its focused module.

- [x] **Step 3: Evaluate the login options**

Run the greetd and DMS assertions from `tests/configuration.sh` for laptop and
desktop. Expected: those assertions pass while user-component assertions still
fail.

### Task 3: Configure the lightweight user stack and static theme

**Files:**
- Modify: `home/itterum/default.nix`
- Modify: `home/itterum/desktop.nix`

**Interfaces:**
- Consumes: `osConfig.services.tlp.enable`, Home Manager graphical-session target and the Catppuccin packages in nixpkgs.
- Produces: Fuzzel, Mako, swayidle and swaylock configuration plus unified GTK/Qt/icon/cursor theming.

- [x] **Step 1: Stop importing the personal Quickshell module**

Remove only `./quickshell.nix` from the Home Manager imports. Do not delete the
file or `itterum-shell/` sources.

- [x] **Step 2: Define the shared static palette and packages**

Define Mocha colors `base = 1e1e2e`, `surface0 = 313244`, `surface1 = 45475a`,
`overlay0 = 6c7086`, `text = cdd6f4`, `subtext0 = a6adc8`, `mauve = cba6f7`,
`blue = 89b4fa`, `green = a6e3a1`, `yellow = f9e2af`, and `red = f38ba8`.
Install `brightnessctl` and `playerctl` as non-daemon helpers.

- [x] **Step 3: Configure Fuzzel and Mako**

Enable Fuzzel with Ghostty, Papirus-Dark icons, a 42-character width, twelve
lines, ten-pixel corners and Mocha colors. Enable Mako at the top right with a
360-pixel width, ten-pixel corners, icons, five-second default timeout, mauve
border and red critical-notification border.

- [x] **Step 4: Configure swaylock and swayidle**

Enable a Mocha swaylock with mauve input highlighting and red failure state.
Configure swayidle to lock after 300 seconds, power monitors off after 600
seconds, restore them on activity, lock before sleep and suspend TLP-enabled
hosts after 1800 seconds.

- [x] **Step 5: Complete GTK and Qt theming**

Set GTK's icon theme to Papirus-Dark. Enable Qt with qtct, Kvantum, a
Catppuccin Mocha Mauve Kvantum package and Papirus-Dark in both qt5ct and
qt6ct settings. Force the generated qtct files so existing mutable settings do
not block Home Manager activation.

### Task 4: Make Niri independent from DMS

**Files:**
- Modify: `home/itterum/files/niri/config.kdl`

**Interfaces:**
- Consumes: the current live DMS-generated output, layout, cursor and binding values.
- Produces: one complete static Niri configuration with no generated includes.

- [x] **Step 1: Inline static output, cursor and layout settings**

Add the current HDMI-A-1 and eDP-1 modes and positions, cursor theme, eight-pixel
gaps, two-pixel mauve focus ring, ten-pixel geometry corners and soft shadow.

- [x] **Step 2: Replace DMS-specific rules and includes**

Remove Quickshell/DMS layer and window rules and all seven `include "dms/..."`
lines. Keep unrelated application window rules.

- [x] **Step 3: Add standalone bindings**

Copy the existing Niri navigation, workspace, sizing, screenshot and session
bindings into a local `binds` block. Replace DMS calls with Fuzzel, swaylock,
Mako, wpctl, brightnessctl and playerctl commands.

- [x] **Step 4: Run the complete regression test**

Run: `bash tests/configuration.sh`

Expected: PASS.

### Task 5: Verify the migration

**Files:**
- Modify only files required to resolve verification failures.

**Interfaces:**
- Consumes: completed Tasks 1-4.
- Produces: evaluated and buildable laptop and desktop configurations.

- [x] **Step 1: Format and inspect**

Run `nixfmt` on changed Nix files, `kdlfmt format` on the Niri source, and
inspect `git diff --check` plus the scoped diff. Preserve unrelated changes.

- [x] **Step 2: Run static checks**

Run:

```bash
bash tests/configuration.sh
nix flake check --no-build
```

Expected: both commands exit 0. Pre-existing dependency warnings must be
reported separately from errors introduced by this migration.

- [x] **Step 3: Build both systems**

Run:

```bash
nix build --no-link .#nixosConfigurations.laptop.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.desktop.config.system.build.toplevel
```

Expected: both commands exit 0.

- [x] **Step 4: Review the final diff**

Confirm DMS has no active import or runtime reference, the personal Quickshell
sources remain untouched, and no unrelated user changes were reverted.
