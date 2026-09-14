# Niri Desktop Restoration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore a portable, buildable physical NixOS workstation configuration with Niri and temporary standalone desktop components.

**Architecture:** Selectively recover the modular layout from commit `697e781` without resetting history. Replace its hardware-specific, Noctalia, and WSL assumptions with a generic UEFI host, standard Niri session services, and a clean future boundary for Itterum Shell.

**Tech Stack:** NixOS 26.05, flakes, Home Manager 26.05, Niri, greetd/tuigreet, Waybar, Fuzzel, Mako, swaybg, swaylock, swayidle

**Spec:** `docs/superpowers/specs/2026-09-14-niri-desktop-restoration-design.md`

## Global Constraints

- Keep `system.stateVersion = "26.05"` and `home.stateVersion = "26.05"`.
- Expose only `nixosConfigurations.desktop` for `x86_64-linux`.
- Keep `itterum-shell` as a local flake input but do not install or start it.
- Do not restore Noctalia, NixOS-WSL, NVIDIA settings, fixed outputs, Limine, Secure Boot enrollment, or Windows boot entries.
- Do not reset, rewrite, commit, or push Git history.
- Use `apply_patch` for repository edits and preserve the approved spec.
- Keep the hardware file as an unmistakable non-installable bootstrap placeholder.

---

### Task 1: Restore the flake and portable host skeleton

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`
- Create: `hosts/desktop/default.nix`
- Create: `hosts/desktop/boot.nix`
- Create: `hosts/desktop/hardware-configuration.nix`
- Create: `profiles/nixos/workstation.nix`
- Create: `profiles/home/workstation.nix`
- Create: `home/itterum/default.nix`
- Create: `tests/configuration.sh`

**Interfaces:**
- Consumes: `nixpkgs`, `home-manager`, `niri-flake`, and local `itterum-shell` inputs
- Produces: `nixosConfigurations.desktop` and `home-manager.users.itterum`

- [ ] **Step 1: Write the failing skeleton checks**

Create strict Bash helpers and add:

```bash
assert_eq '["desktop"]' \
  "$(nix eval --json "${flake_ref}#nixosConfigurations" --apply builtins.attrNames)" \
  "flake configurations"
assert_eq "desktop" "$(flake_value desktop networking.hostName)" "desktop hostname"
assert_eq '"26.05"' "$(flake_json desktop system.stateVersion)" "system state version"
assert_eq '"26.05"' \
  "$(flake_json desktop home-manager.users.itterum.home.stateVersion)" \
  "home state version"
```

- [ ] **Step 2: Run the test and observe the WSL-era failure**

```bash
bash tests/configuration.sh
```

Expected: failure because the current flake exposes `wsl` and references a missing top-level hardware file.

- [ ] **Step 3: Restore modular flake composition**

Adapt `flake.nix` from `697e781` so its inputs are exactly `nixpkgs`, `home-manager`, `niri-flake`, and `itterum-shell`. Pass `inputs` through both special-argument mechanisms, import `./home/itterum`, and expose `nixosConfigurations.desktop = mkSystem ./hosts/desktop;`.

- [ ] **Step 4: Create portable host files**

Create the desktop host with hostname `desktop` and state version `26.05`. Configure systemd-boot, writable EFI variables, and a five-second timeout. Create a hardware placeholder importing `not-detected.nix`, setting `x86_64-linux`, and declaring an ext4 root at `/dev/disk/by-label/REPLACE_ME_DESKTOP_ROOT`.

- [ ] **Step 5: Restore entry points and refresh the lock**

Create both profile files with empty imports and the Home Manager entry with user `itterum`, `/home/itterum`, state version `26.05`, and Home Manager enabled. Run:

```bash
nix flake lock path:.
bash tests/configuration.sh
```

Expected: the lock refresh succeeds and Task 1 assertions pass.

### Task 2: Restore portable NixOS workstation services

**Files:**
- Create: `modules/nixos/system/{fonts,locale,nix,tools,users}.nix`
- Create: `modules/nixos/desktop/{audio,niri,portals,session,greeter,services}.nix`
- Create: `modules/nixos/hardware/bluetooth.nix`
- Create: `modules/nixos/network/default.nix`
- Create: `modules/nixos/virtualisation/containers.nix`
- Modify: `profiles/nixos/workstation.nix`
- Modify: `tests/configuration.sh`

**Interfaces:**
- Consumes: `inputs.niri-flake` and NixOS module options
- Produces: a login-capable Niri system with desktop services

- [ ] **Step 1: Add failing system assertions**

Assert Niri, greetd, PipeWire, NetworkManager, Bluetooth, portals, polkit, GNOME Keyring, udisks2, gvfs, upower, Podman, systemd-boot, and user groups. Assert WSL and Limine are disabled and video drivers contain no `nvidia`.

- [ ] **Step 2: Run and confirm the missing service failure**

```bash
bash tests/configuration.sh
```

Expected: failure on the first absent workstation service.

- [ ] **Step 3: Restore and simplify system modules**

Recover reusable modules from `697e781`. Remove CUDA Ollama, casting, Kanata, Flatpak, and hardware-specific imports. Keep flakes, weekly GC, optimisation, `nix-ld`, Zsh, fonts, locale, NetworkManager, Podman Docker compatibility, and desktop device services.

- [ ] **Step 4: Implement Niri login and portals**

Use the Niri flake module, enable Niri, configure greetd with `tuigreet` to launch `niri-session`, enable polkit and GNOME Keyring, and enable GTK plus Niri-compatible portals.

- [ ] **Step 5: Compose and verify the system profile**

Import all created modules from `profiles/nixos/workstation.nix`, then run:

```bash
bash tests/configuration.sh
nix eval --raw path:.#nixosConfigurations.desktop.config.system.build.toplevel.drvPath
```

Expected: Task 2 assertions pass and evaluation prints one derivation path.

### Task 3: Restore shell, editor, and applications

**Files:**
- Create: `modules/home/shell/{default,tools,zsh}.nix`
- Create: `modules/home/programs/ghostty.nix`
- Create: `modules/home/programs/apps.nix`
- Create: `modules/home/programs/helix/{default,editor}.nix`
- Create: `modules/home/programs/helix/languages/{default,misc,python,rust,web}.nix`
- Modify: `profiles/home/workstation.nix`
- Modify: `tests/configuration.sh`

**Interfaces:**
- Consumes: Home Manager and pinned Nixpkgs
- Produces: CLI environment, Ghostty, Helix, Firefox, Nautilus, KeePassXC, Telegram Desktop, and Obsidian

- [ ] **Step 1: Add failing Home Manager assertions**

Assert Zsh, Starship, direnv/nix-direnv, Git, Ghostty, Firefox, and Helix. Assert packages include `ripgrep`, `fd`, `jq`, `tree`, `uv`, `kubectl`, `k9s`, `codex`, `nautilus`, `keepassxc`, `telegram-desktop`, and `obsidian`.

- [ ] **Step 2: Run and confirm the first absent program failure**

```bash
bash tests/configuration.sh
```

Expected: failure on the first absent Home Manager program.

- [ ] **Step 3: Restore focused user modules**

Recover split shell and Helix modules from `697e781`, merge relevant settings from current `home.nix` and `helix.nix`, and keep every program declared once. Add only the graphical applications in the task interface.

- [ ] **Step 4: Compose and verify Home Manager**

Import shell, Ghostty, apps, and Helix modules from the Home Manager profile and run `bash tests/configuration.sh`.

Expected: Task 3 assertions pass without duplicate option-definition errors.

### Task 4: Restore generic Niri and fallback UI

**Files:**
- Create: `modules/home/desktop/default.nix`
- Create: `modules/home/desktop/fallback.nix`
- Create: `modules/home/desktop/theme.nix`
- Create: `modules/home/desktop/niri/{default,animations,appearance,input,rules}.nix`
- Create: `modules/home/desktop/niri/binds/{default,applications,media,session,windows,workspaces}.nix`
- Modify: `profiles/home/workstation.nix`
- Modify: `tests/configuration.sh`

**Interfaces:**
- Consumes: `osConfig.programs.niri.package`
- Produces: generated Niri KDL and Waybar, Fuzzel, Mako, swaybg, swaylock, and swayidle

- [ ] **Step 1: Add failing desktop assertions**

Assert all fallback programs and services are enabled. Assert Niri final config contains Ghostty and Fuzzel bindings plus workspace, window, and media actions. Assert it contains no `noctalia`, `hyprctl`, fixed output block, or Itterum Shell startup.

- [ ] **Step 2: Run and confirm the missing desktop module failure**

```bash
bash tests/configuration.sh
```

Expected: failure because no Home Manager desktop module is imported.

- [ ] **Step 3: Restore portable Niri modules**

Recover generic input, animation, appearance, rules, window, workspace, media, and session settings from `697e781`. Do not restore `outputs.nix`, Noctalia commands, named-monitor movement bindings, or the invalid-serial debug workaround.

- [ ] **Step 4: Add fallback services and bindings**

Create `fallback.nix` enabling Waybar, Fuzzel, Mako, swaybg with `assets/wallpapers/nix-wallpaper.png`, swaylock, and swayidle. Lock after 300 seconds and power off displays after 600 seconds. Start Waybar, Mako, and swaybg from Niri startup. Bind `Mod+Space` to Fuzzel, `Mod+Alt+L` to swaylock, and terminal shortcuts to Ghostty.

- [ ] **Step 5: Verify generated KDL**

```bash
bash tests/configuration.sh
nix eval --raw \
  path:.#nixosConfigurations.desktop.config.home-manager.users.itterum.programs.niri.finalConfig
```

Expected: assertions pass and KDL contains only portable fallback commands.

### Task 5: Remove WSL layout and document installation

**Files:**
- Delete: `configuration.nix`
- Delete: `home.nix`
- Delete: `helix.nix`
- Modify: `README.md`
- Modify: `.gitignore`
- Modify: `tests/configuration.sh`

**Interfaces:**
- Consumes: completed desktop configuration from Tasks 1-4
- Produces: one coherent repository layout and installation documentation

- [ ] **Step 1: Add structural assertions**

Assert the three WSL-era files are absent; required host, profile, and module files exist; `itterum-shell` remains present; and flake metadata contains no NixOS-WSL or Noctalia input.

- [ ] **Step 2: Remove superseded files**

Delete the three top-level files with `apply_patch`, run `bash tests/configuration.sh`, and correct only references intended to move into restored modules.

- [ ] **Step 3: Rewrite README**

Document layout, fallback desktop, deferred Itterum Shell integration, check commands, replacement of the hardware placeholder with `nixos-generate-config`, UEFI `/boot`, `nixos-install --flake path:.#desktop`, password setup, rebuild, rollback, and garbage collection.

- [ ] **Step 4: Run full verification**

```bash
nixfmt $(rg --files -g '*.nix' -g '!itterum-shell/**')
bash tests/configuration.sh
nix flake check path:. --no-build
nix build --no-link \
  path:.#nixosConfigurations.desktop.config.system.build.toplevel
git diff --check
git status --short --branch
git diff --stat
```

Expected: all commands succeed; Git shows only intended restoration, docs, lock update, and removal of the three WSL files; no commit exists.
