# VM and WSL Profiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a headless NixOS-WSL profile with the shared CLI environment, native Docker, and a safe migration from user `nixos` to `itterum`, while preserving the graphical VM profiles.

**Architecture:** Keep `home/itterum.nix` as the shared CLI baseline and compose it differently per host. The WSL output imports the official release-matched NixOS-WSL module plus a focused local configuration; VM hardware and GUI modules remain isolated under the VM host.

**Tech Stack:** Nix flakes, flake-parts, import-tree, NixOS 26.05, NixOS-WSL release-26.05, Home Manager 26.05, systemd, Docker.

**Spec:** `docs/superpowers/specs/2026-10-05-wsl-vm-profile-design.md`

## Global Constraints

- Keep `vm`, `vm-gnome`, and `vm-kde` as graphical VM outputs.
- Add exactly one headless output named `wsl`.
- Pin NixOS-WSL to `github:nix-community/NixOS-WSL/release-26.05` and make its `nixpkgs` input follow this flake's `nixpkgs`.
- Use `itterum` as `wsl.defaultUser` with UID `1001`; retain user `nixos`, UID
  `1000`, and `/home/nixos`.
- Set WSL automount ownership to `uid=1001,gid=100` for `itterum:users`.
- WSL imports the shared Home Manager baseline and Helix, but no Zed, ChatGPT, GNOME, or KDE modules.
- WSL uses native Docker through `virtualisation.docker.enable = true`; do not enable Docker Desktop integration.
- Keep `system.stateVersion` and `home.stateVersion` at `26.05`.
- Do not activate a configuration that has not evaluated and built successfully.
- Change the installed default WSL user with `nixos-rebuild boot`, never `switch`.
- Copy user data without overwriting conflicts; do not migrate `.cache` or the Home Manager-managed `.config/helix` directory.
- Do not delete the old account, old home, or rollback generation.

## Review Focus

- A WSL host must not inherit VM disks or bootloader settings; Task 1 asserts the WSL bootloader is disabled and the copied hardware module is absent.
- The NixOS-WSL default user, system user, Home Manager user, and home path must all be `itterum`, while `nixos` retains UID `1000`; Task 1 evaluates the identities and non-conflicting UIDs together.
- Native Docker must be enabled without Docker Desktop and `itterum` must be in the `docker` group; Task 1 evaluates these values before activation.
- Adding WSL must not regress either graphical desktop; Task 1 evaluates and builds both `vm-gnome` and `vm-kde` as well as the compatibility alias `vm`.
- Existing destination data must never be overwritten during migration; Task 2 uses explicit preflight conflict checks and retains `/home/nixos` unchanged.

---

### Task 1: Build the Declarative WSL Profile

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`
- Modify: `modules/hosts/wsl/default.nix`
- Modify: `modules/hosts/wsl/configuration.nix`
- Remove: `modules/hosts/wsl/hardware.nix`

**Interfaces:**
- Consumes: `self.nixosModules.wslConfig`, `self.homeModules.helix`, `home/itterum.nix`, `inputs.home-manager.nixosModules.home-manager`, and `inputs.nixos-wsl.nixosModules.default`.
- Produces: `nixosConfigurations.wsl`, whose evaluated configuration has `wsl.enable = true`, `wsl.defaultUser = "itterum"`, and native Docker enabled.

- [ ] **Step 1: Record the current failing WSL evaluation**

Run:

```bash
nix eval 'path:.#nixosConfigurations.wsl.config.wsl.enable' --json
```

Expected: FAIL because the copied WSL directory does not export a valid `wsl` configuration and conflicts with the VM module names.

- [ ] **Step 2: Add the release-matched NixOS-WSL input**

In `flake.nix`, add input `nixos-wsl` with URL
`github:nix-community/NixOS-WSL/release-26.05` and
`inputs.nixpkgs.follows = "nixpkgs"`.

- [ ] **Step 3: Update only the new lock-file input**

Run:

```bash
nix flake update nixos-wsl
```

Expected: `flake.lock` gains NixOS-WSL nodes without changing the pinned revisions of unrelated direct inputs.

- [ ] **Step 4: Export the WSL system**

Rewrite `modules/hosts/wsl/default.nix` so `flake.nixosConfigurations.wsl`
uses `inputs.nixpkgs.lib.nixosSystem` and imports, in order,
`inputs.nixos-wsl.nixosModules.default` and `self.nixosModules.wslConfig`.
Do not define any `vm*` output from this file.

- [ ] **Step 5: Implement the focused WSL module**

Rewrite `modules/hosts/wsl/configuration.nix` to export
`flake.nixosModules.wslConfig`. It must:

- import Home Manager only;
- configure Home Manager for `itterum` with `self.homeModules.helix` and
  `../../../home/itterum.nix`;
- enable flakes, `wsl`, `programs.nix-ld`, and native Docker;
- set default user `itterum`, hostname `nixos-wsl`, timezone `Europe/Minsk`,
  locale `en_US.UTF-8`, and state version `26.05`;
- declare `nixos` as a retained normal user with UID `1000` and home
  `/home/nixos`, keeping it in `wheel` for recovery;
- override the NixOS-WSL default and assign `itterum` UID `1001`, merge
  `docker` into its groups, and rely on the NixOS-WSL module for its `wheel`
  membership;
- set `wsl.wslConf.automount.options` to `metadata,uid=1001,gid=100`;
- contain no VM hardware, desktop, audio, printing, networking-manager,
  Flatpak, Firefox, Zed, or ChatGPT configuration.

- [ ] **Step 6: Remove copied VM hardware from WSL**

Delete `modules/hosts/wsl/hardware.nix`. Verify no file under
`modules/hosts/wsl` refers to `vmHardware`, a disk UUID, `systemd-boot`, or an
EFI variable.

Run:

```bash
rg -n 'vmHardware|by-uuid|systemd-boot|canTouchEfiVariables' modules/hosts/wsl
```

Expected: exit status 1 with no matches.

- [ ] **Step 7: Format the Nix sources**

Run:

```bash
nix fmt
```

Expected: exit status 0; inspect `git diff` and retain only formatting related to this task.

- [ ] **Step 8: Evaluate the WSL contract**

Run one `nix eval --impure --json --expr` expression that loads
`builtins.getFlake "path:$PWD"` and returns these exact fields from
`nixosConfigurations.wsl.config`:

- `wsl.enable` equals `true`;
- `wsl.defaultUser` equals `"itterum"`;
- `networking.hostName` equals `"nixos-wsl"`;
- `time.timeZone` equals `"Europe/Minsk"`;
- `users.users.itterum.isNormalUser` equals `true`;
- `users.users.nixos.uid` equals `1000`;
- `users.users.itterum.uid` equals `1001`;
- `users.users.itterum.home` equals `/home/itterum`;
- `wsl.wslConf.automount.options` equals `"metadata,uid=1001,gid=100"`;
- `users.users.itterum.extraGroups` contains both `wheel` and `docker`;
- `home-manager.users.itterum.home.username` equals `"itterum"`;
- `virtualisation.docker.enable` equals `true`;
- `wsl.docker-desktop.enable` equals `false`;
- `boot.loader.systemd-boot.enable`, `networking.networkmanager.enable`,
  `services.printing.enable`, `services.pipewire.enable`, and
  `services.flatpak.enable` all equal `false`.

Expected: exit status 0 and JSON values matching every assertion.

- [ ] **Step 9: Run whole-flake evaluation and build every distinct host**

Run:

```bash
nix flake check 'path:.'
nix build --no-link 'path:.#nixosConfigurations.wsl.config.system.build.toplevel'
nix build --no-link 'path:.#nixosConfigurations.vm-gnome.config.system.build.toplevel'
nix build --no-link 'path:.#nixosConfigurations.vm-kde.config.system.build.toplevel'
nix eval 'path:.#nixosConfigurations.vm.config.system.build.toplevel.drvPath' --raw
```

Expected: every command exits 0. The last command proves the compatibility
alias still evaluates; `vm-gnome` and `vm-kde` each receive a full build.

- [ ] **Step 10: Commit the declarative profile**

```bash
git add flake.nix flake.lock modules/hosts/wsl/default.nix modules/hosts/wsl/configuration.nix
git commit -m "feat: add headless NixOS WSL profile"
```

Expected: the commit contains only the flake input/lock and WSL host files.

### Task 2: Activate the New User and Migrate Persistent Data

**Files:**
- Copy at runtime: `/home/nixos/nixos-config` to `/home/itterum/nixos-config`
- Copy at runtime: `/home/nixos/.ssh` contents to `/home/itterum/.ssh`
- Preserve: `/home/nixos`, `/home/nixos/.cache`, and `/home/nixos/.config/helix`

**Interfaces:**
- Consumes: the successfully built `nixosConfigurations.wsl` system from Task 1 and Windows distribution name `NixOS`.
- Produces: a default `itterum` login with migrated repository and SSH data, working Home Manager CLI tools, and an active native Docker service.

- [ ] **Step 1: Run activation preflight inside the existing `nixos` session**

Run:

```bash
test "$(whoami)" = nixos
test -d /home/nixos/nixos-config
test ! -e /home/itterum/nixos-config
sudo -n true
nix build --no-link '.#nixosConfigurations.wsl.config.system.build.toplevel'
```

Expected: all commands exit 0. Stop if the destination repository already
exists or passwordless sudo is unavailable.

- [ ] **Step 2: Install the new generation for the next WSL boot**

Run from `/home/nixos/nixos-config`:

```bash
sudo nixos-rebuild boot --flake '.#wsl'
```

Expected: exit status 0 and a new boot generation. Do not substitute `switch`.

- [ ] **Step 3: Apply the default-user change from PowerShell**

Exit every shell in the `NixOS` distribution, then run:

```powershell
wsl.exe --terminate NixOS
wsl.exe -d NixOS --user root -- exit
wsl.exe --terminate NixOS
```

Expected: all commands exit 0. These commands must be run by the user because
terminating the distribution also terminates the active implementation shell.

- [ ] **Step 4: Verify the new default session before copying data**

Open `NixOS` normally and run:

```bash
test "$(whoami)" = itterum
test "$HOME" = /home/itterum
test "$(id -u itterum)" = 1001
test "$(id -u nixos)" = 1000
id -nG | grep -qw wheel
id -nG | grep -qw docker
test -d /mnt/c
test "$(stat -c '%u:%g' /mnt/c)" = 1001:100
test -d /home/nixos
getent passwd nixos
sudo -n true
```

Expected: every check exits 0; the old user and home still exist.

- [ ] **Step 5: Check migration destinations for conflicts**

Run:

```bash
test ! -e /home/itterum/nixos-config
test ! -e /home/itterum/.ssh
```

Expected: both checks exit 0. If either fails, inspect the conflicting path and
stop; do not overwrite it.

- [ ] **Step 6: Copy the repository and SSH data without touching the source**

Run:

```bash
sudo cp -a /home/nixos/nixos-config /home/itterum/nixos-config
sudo cp -a /home/nixos/.ssh /home/itterum/.ssh
sudo chown -R itterum:users /home/itterum/nixos-config /home/itterum/.ssh
sudo chmod 700 /home/itterum/.ssh
```

Expected: exit status 0. Do not copy `.cache` or `.config/helix`; Home Manager
owns the latter in the new home.

- [ ] **Step 7: Verify migrated ownership and CLI tools without exposing secrets**

Run:

```bash
test "$(stat -c '%U:%G' /home/itterum/nixos-config)" = itterum:users
test "$(stat -c '%U:%G' /home/itterum/.ssh)" = itterum:users
test "$(stat -c '%a' /home/itterum/.ssh)" = 700
test -f /home/itterum/.ssh/id_ed25519
for command in git gh hx rg fd jq uv kubectl k9s; do command -v "$command" >/dev/null || exit 1; done
```

Expected: every check exits 0. Do not print private-key contents.

- [ ] **Step 8: Verify native Docker end to end**

Run:

```bash
systemctl is-active --quiet docker
docker info >/dev/null
docker run --rm hello-world
```

Expected: service and daemon checks exit 0, and the test container prints its
success message. Docker Desktop is not required or used.

- [ ] **Step 9: Record the final boundary**

Report separately:

- verified: flake checks/builds, `itterum` default login, data ownership, CLI
  availability, and native Docker container execution;
- preserved: the `nixos` account and original `/home/nixos` data;
- unverified, if applicable: an actual graphical boot of each VM profile,
  because a successful Nix build does not prove VMware runtime behavior.
