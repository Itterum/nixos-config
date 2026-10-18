# Weaselway WSL Migration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the physical-PC host with one buildable Weaselway Plasma configuration for the installed NixOS-WSL system while retaining the approved developer and KDE environment.

**Architecture:** Use Weaselway's pinned nixpkgs and NixOS-WSL inputs for the only host, `nixosConfigurations.nixos`. Layer the local system policy and Home Manager configuration for user `nixos` over Weaselway, while Plasma Manager owns appearance and panels but not session startup.

**Tech Stack:** NixOS 26.05, NixOS-WSL, Weaselway, flake-parts, import-tree, Home Manager, Plasma Manager, Bash evaluation tests

**Spec:** `docs/superpowers/specs/2026-10-18-weaselway-wsl-migration-design.md`

## Global Constraints

- Export only `nixosConfigurations.nixos` for hostname `nixos`.
- Keep user `nixos`, UID 1000, home `/home/nixos`, and `system.stateVersion = "26.05"`.
- Weaselway remains the sole owner of the graphical session, patched graphics stack, viewer, input, and audio integration.
- Plasma is enabled without SDDM or another display manager.
- Keep native Docker, Brave, Zed, Foot, Helix, GitHub SSH settings, and the existing CLI baseline.
- Keep only Dolphin, Foot, Brave, and Zed in the bottom dock.
- Do not retain physical-PC boot, disk, NVIDIA, Sunshine, gaming, Flatpak, ChatGPT, Chrome, JetBrains, or Caffeine configuration.
- Do not encode the current user's password or activate the resulting generation automatically.

## Review Focus

- A mismatched nixpkgs could replace Weaselway's patched graphics packages; `tests/system.sh` pins the shared nixpkgs revision relationship and Weaselway Mesa package.
- A user mismatch could break WSL runtime paths and Windows mounts; `tests/system.sh` pins the default user, UID, home, and mutable-password policy.
- Enabling a display manager could conflict with `ww-start-session`; `tests/system.sh` pins Plasma on and SDDM off.
- A Home Manager rename could leave files under `/home/itterum`; `tests/home.sh` pins every user and home path to `nixos` and `/home/nixos`.
- Removed applications could leave dead menu or dock entries; `tests/kde.sh` pins the complete launcher and Kpple Menu command lists.

---

### Task 1: Weaselway Host and Flake Inputs

**Files:**
- Create: `tests/system.sh`
- Create: `modules/hosts/wsl/default.nix`
- Create: `modules/hosts/wsl/configuration.nix`
- Modify: `flake.nix`
- Modify: `flake.lock`
- Delete: `modules/hosts/pc/`
- Delete: `modules/features/chatgpt.nix`
- Delete: `modules/features/caffeine.nix`
- Delete: `home/caffeine/`
- Delete: `tests/boot.sh`
- Delete: `tests/caffeine.sh`
- Delete: `tests/maintenance.sh`

**Interfaces:**
- Consumes: `inputs.weaselway.inputs.nixpkgs`, `inputs.weaselway.inputs.nixos-wsl.nixosModules.default`, and `inputs.weaselway.nixosModules.weaselway`.
- Produces: `nixosConfigurations.nixos` and `nixosModules.wslConfig`, with the installed Weaselway system policy, Brave, and native Docker.

- [ ] **Step 1: Write the failing system evaluation test**

Create executable `tests/system.sh`. Have one Nix expression load the path flake and assert these exact values before returning `"ok"`:

- output `nixosConfigurations.nixos` exists;
- hostname and WSL default user are `nixos`;
- UID is 1000 and home is `/home/nixos`;
- mutable users remain enabled and no initial plaintext password is declared;
- WSL, Weaselway, Plasma, and Docker are enabled;
- Weaselway's session is `plasma` and SDDM is disabled;
- `nixos` belongs to `docker`, `render`, `video`, and `input`;
- `hardware.graphics.package` is the host package set's `weaselway-mesa`;
- Brave belongs to `environment.systemPackages`;
- no boot loader is enabled and none of the former PC disk UUIDs occurs in the evaluated filesystem devices;
- the reduced Plasma packages and accessibility services match the spec.

- [ ] **Step 2: Run the system test to verify it fails**

Run: `bash tests/system.sh`

Expected: FAIL because `nixosConfigurations.nixos` does not exist.

- [ ] **Step 3: Replace the flake's package source and host inputs**

In `flake.nix`, add `weaselway`, make top-level `nixpkgs` follow
`weaselway/nixpkgs`, keep flake-parts/import-tree, and make Home Manager and
Plasma Manager follow that package set. Remove wrapper-modules and
nixos-chatgpt. Keep `x86_64-linux` and `nixfmt-tree`.

Run: `nix flake lock`

Expected: `flake.lock` pins Weaselway and its nested dxgdrm, FreeRDP, Mesa, and
NixOS-WSL inputs while dropping inputs reachable only from removed features.

- [ ] **Step 4: Implement the WSL host**

Create `nixosConfigurations.nixos` with the three-module composition from the
spec. In `wslConfig`, reproduce the installed Weaselway Plasma policy, keep
the current hostname/user/state version, omit the plaintext password, enable
Brave and native Docker, and add `nixos` to `docker`. Do not import the image
helper or any physical-PC module.

Delete the physical host and the feature files whose inputs were removed.

- [ ] **Step 5: Run the system test and build the host**

Run: `bash tests/system.sh`

Expected: PASS with `Weaselway WSL system assertions passed`.

Run: `nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel`

Expected: exit 0 and no local build of Weaselway's patched graphics stack when its cache is available.

- [ ] **Step 6: Commit the system host**

```bash
git add flake.nix flake.lock modules/hosts modules/features home/caffeine tests
git commit -m "feat: migrate host to Weaselway WSL"
```

### Task 2: NixOS User Home and Developer Applications

**Files:**
- Create: `tests/home.sh`
- Create: `home/nixos.nix`
- Modify: `modules/hosts/wsl/configuration.nix`
- Delete: `home/itterum.nix`

**Interfaces:**
- Consumes: `self.homeModules.github`, `self.homeModules.helix`, `self.homeModules.zedEditor`, and Home Manager's NixOS module.
- Produces: `home-manager.users.nixos` rooted at `/home/nixos`, with the existing CLI baseline, Helix, GitHub SSH configuration, and Zed.

- [ ] **Step 1: Write the failing Home Manager evaluation test**

Create executable `tests/home.sh`. Assert through one Nix expression that:

- `home-manager.users.nixos.home.username` is `nixos` and its home directory is `/home/nixos`;
- `home.stateVersion` remains `26.05`;
- Home Manager uses global and user packages;
- Git name/email and the GitHub SSH identity file retain their existing exact values;
- Helix and Zed are enabled, Zed settings remain immutable, and the configured extensions remain present;
- the CLI baseline contains `ripgrep`, `fd`, `jq`, `uv`, `kubectl`, and `k9s`;
- no `home-manager.users.itterum` definition exists.

- [ ] **Step 2: Run the home test to verify it fails**

Run: `bash tests/home.sh`

Expected: FAIL because the host has no Home Manager user named `nixos`.

- [ ] **Step 3: Rename and wire the shared home**

Create `home/nixos.nix` from the existing baseline, changing only the username
and home directory. Import Home Manager in `wslConfig`, enable global/user
packages, and compose the baseline with GitHub, Helix, and Zed. Remove
`home/itterum.nix`.

- [ ] **Step 4: Run the home test and rebuild**

Run: `bash tests/home.sh`

Expected: PASS with `NixOS Home Manager assertions passed`.

Run: `nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel`

Expected: exit 0.

- [ ] **Step 5: Commit the home migration**

```bash
git add home modules/hosts/wsl/configuration.nix tests/home.sh
git commit -m "feat: configure nixos developer home"
```

### Task 3: Plasma Manager Adaptation

**Files:**
- Create: `tests/kde.sh`
- Modify: `home/kde/default.nix`
- Modify: `modules/hosts/wsl/configuration.nix`
- Delete: `tests/foot.sh`
- Delete: `tests/kde-panels.sh`
- Delete: `tests/wallpaper.sh`

**Interfaces:**
- Consumes: `self.homeModules.kde`, `self.homeModules.foot`, Plasma Manager, and system-provided Dolphin/Brave desktop entries.
- Produces: the approved Weaselway-compatible Plasma appearance, menu, Foot terminal setting, and four-item dock.

- [ ] **Step 1: Write the failing KDE evaluation test**

Create executable `tests/kde.sh`. Assert:

- Plasma Manager and Foot are enabled for `nixos`;
- Konsole is excluded and Foot's font/window settings retain their exact values;
- the wallpaper is shared by the desktop and lock screen;
- WhiteSur icon and cursor themes and Kpple Menu are installed;
- there are exactly two panels with the approved top-panel clock and bottom-dock geometry;
- the dock launcher list is exactly Dolphin, Foot, Brave, and Zed, in that order;
- Kpple Menu contains exactly About This Computer, System Settings, Lock Screen, and Log Out plus the approved dividers, with no Discover, restart, or shutdown command.

- [ ] **Step 2: Run the KDE test to verify it fails**

Run: `bash tests/kde.sh`

Expected: FAIL because the old configuration still has seven physical-PC launchers and menu actions.

- [ ] **Step 3: Adapt KDE and compose its Home Manager modules**

Update `home/kde/default.nix` to the exact menu and launcher lists from the
spec. Import KDE and Foot for `home-manager.users.nixos`; exclude Konsole at
the system layer. Do not add SDDM or its former generated theme.

Delete the superseded PC-specific KDE test scripts.

- [ ] **Step 4: Run the KDE test and realize visual assets**

Run: `bash tests/kde.sh`

Expected: PASS with `Weaselway KDE assertions passed`; the test realizes the wallpaper and confirms its existing SHA-256 digest.

Run: `nix build --no-link .#nixosConfigurations.nixos.config.system.build.toplevel`

Expected: exit 0.

- [ ] **Step 5: Commit the KDE adaptation**

```bash
git add home/kde modules/hosts/wsl/configuration.nix tests
git commit -m "feat: adapt KDE desktop for Weaselway"
```

### Task 4: Full Repository Verification

**Files:**
- Modify: any Nix files changed mechanically by the repository formatter

**Interfaces:**
- Consumes: the system, home, and KDE deliverables from Tasks 1-3.
- Produces: one formatted, evaluated, fully built configuration ready for user-controlled activation.

- [ ] **Step 1: Format the Nix source**

Run: `nix fmt`

Expected: exit 0; only touched Nix files receive mechanical formatting changes.

- [ ] **Step 2: Run every repository test**

Run: `for test in tests/*.sh; do bash "$test"; done`

Expected: all three scripts pass.

- [ ] **Step 3: Check the flake**

Run: `nix flake check --show-trace`

Expected: exit 0.

- [ ] **Step 4: Build the final system closure**

Run: `nix build --no-link --print-out-paths .#nixosConfigurations.nixos.config.system.build.toplevel`

Expected: one `/nix/store/...-nixos-system-nixos-26.05...` output and exit 0.

- [ ] **Step 5: Inspect the final diff and commit formatter changes if any**

Run: `git diff --check && git status --short && git diff --stat HEAD~3..HEAD`

Expected: no whitespace errors, no unexpected files, and no activation of the running system.

If formatting changed tracked files after Task 3:

```bash
git add '*.nix' modules home
git commit -m "style: format Weaselway configuration"
```

- [ ] **Step 6: Hand off activation and runtime checks**

Report the built store path and the unexecuted activation command:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

After user-controlled activation, verify the Weaselway system and user
services, restart the Plasma session, and test Docker, Brave, and Zed as listed
in the spec. Do not run these state-changing or graphical runtime steps during
implementation.
