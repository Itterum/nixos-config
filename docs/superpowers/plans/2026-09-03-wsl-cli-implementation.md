# Portable NixOS-WSL CLI Configuration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Replace the desktop repository with one portable NixOS-WSL CLI configuration and migrate the active account from nixos to itterum while preserving UID 1000.

**Architecture:** One wsl NixOS flake output imports NixOS-WSL and Home Manager. System settings live in configuration.nix, user CLI settings in home.nix, and editor settings in helix.nix. A Bash evaluation test enforces portability and the absence of desktop packages.

**Tech Stack:** NixOS 26.05, Nix flakes, NixOS-WSL, Home Manager 26.05, Bash, systemd, rootless Podman.

**Spec:** docs/superpowers/specs/2026-09-03-wsl-cli-design.md

## Global Constraints

- Expose only nixosConfigurations.wsl for x86_64-linux.
- Use itterum as the WSL default user with UID 1000, home /home/itterum, and Zsh.
- Preserve system.stateVersion 25.05 and use home.stateVersion 26.05.
- Do not configure desktop services, GUI packages, Distrobox, hardware-specific settings, secrets, or Windows-specific paths.
- Keep Podman with Docker command compatibility.
- Build successfully before renaming the active account.
- Back up /etc/nixos and retain root rollback access.

---

### Task 1: Define configuration invariants

**Files:**
- Replace: tests/configuration.sh

**Interfaces:**
- Consumes: the desired nixosConfigurations.wsl.config output.
- Produces: a regression command that initially fails against the desktop flake and passes after Task 2.

- [ ] **Step 1: Write the WSL regression test**

Use path:$repo_root so new files participate before Git staging. Add raw and JSON evaluation helpers. Assert the following exact evaluated values:

~~~text
nixosConfigurations attribute names = ["wsl"]
networking.hostName = "nixos-wsl"
wsl.enable = true
wsl.defaultUser = "itterum"
users.users.itterum.uid = 1000
users.users.itterum.home = "/home/itterum"
system.stateVersion = "25.05"
home-manager.users.itterum.home.stateVersion = "26.05"
virtualisation.podman.enable = true
virtualisation.podman.dockerCompat = true
~~~

Evaluate Home Manager packages once and require codex, kubectl, k9s, teleport, uv, ripgrep, and nixfmt. Reject distrobox and known graphical packages. Assert Zsh, Git, Helix, Starship, direnv, tmux, bat, eza, fzf, zoxide, btop, and GitHub CLI are enabled.

- [ ] **Step 2: Prove the test fails against the old structure**

Run:

~~~bash
bash tests/configuration.sh
~~~

Expected: nonzero because the old flake exposes desktop and lacks wsl.

---

### Task 2: Replace the repository with the compact WSL flake

**Files:**
- Replace: flake.nix
- Update: flake.lock
- Create: configuration.nix
- Create: home.nix
- Create: helix.nix
- Delete: assets, experiments, home, hosts, modules, profiles
- Delete: old design and plan documents, retaining the 2026-09-03 WSL documents

**Interfaces:**
- Consumes: Nixpkgs nixos-26.05, Home Manager release-26.05, NixOS-WSL main.
- Produces: nixosConfigurations.wsl for tests and nixos-rebuild.

- [ ] **Step 1: Write flake.nix**

Use exactly three direct inputs. Make the NixOS-WSL and Home Manager nixpkgs inputs follow the root nixpkgs. Define one x86_64-linux nixosSystem importing nixos-wsl.nixosModules.default, home-manager.nixosModules.home-manager, and ./configuration.nix.

- [ ] **Step 2: Write configuration.nix**

Set hostname nixos-wsl, enable WSL, and set defaultUser to itterum. Declare itterum with UID 1000, /home/itterum, Zsh, wheel membership, and 65536-entry subordinate UID/GID ranges beginning at 100000. Use passwordless wheel sudo so a clean WSL remains manageable before a password is set.

Enable nix-command and flakes, nix-ld, store optimisation, weekly garbage collection older than 14 days, unfree packages, and rootless Podman with dockerCompat and DNS. Install Git, curl, wget, and Vim system-wide for recovery. Configure Home Manager for itterum with global/user packages, hm-backup, and ./home.nix. Set system.stateVersion to 25.05.

- [ ] **Step 3: Write home.nix**

Import ./helix.nix. Set username itterum, home /home/itterum, stateVersion 26.05, and enable Home Manager. Install:

~~~nix
with pkgs; [
  ripgrep fd tree jq fastfetch uv kubectl k9s teleport
  nixfmt codex
]
~~~

Enable Zsh completion, autosuggestions, syntax highlighting, the existing case-insensitive completion matcher, and completion selection menu. Enable Starship, direnv with nix-direnv, Git, GitHub CLI, tmux, btop, bat, eza, fzf, and zoxide. Set EDITOR and VISUAL to hx.

- [ ] **Step 4: Consolidate Helix into helix.nix**

Preserve current editor settings, transparent theme, language servers, formatter commands, and extra packages. Keep these language names once each: typescript, tsx, javascript, jsx, rust, python, c-sharp, nix, qml, json, toml, markdown, bash, kdl.

- [ ] **Step 5: Prune old files and regenerate the lock**

Remove every obsolete directory listed in this task. Run:

~~~bash
nix flake lock --recreate-lock-file
~~~

Confirm old graphical and agent inputs no longer appear.

- [ ] **Step 6: Make the regression test pass and build**

Run:

~~~bash
bash tests/configuration.sh
nix flake check path:. --no-build
nix build --no-link 'path:.#nixosConfigurations.wsl.config.system.build.toplevel'
~~~

Expected: all exit zero.

- [ ] **Step 7: Commit**

~~~bash
git add -A
git commit -m "replace desktop config with portable WSL CLI host"
~~~

---

### Task 3: Document installation and recovery

**Files:**
- Replace: README.md

**Interfaces:**
- Consumes: flake output .#wsl and repository path ~/nixos-config.
- Produces: reproducible commands for current and fresh NixOS-WSL instances.

- [ ] **Step 1: Write README.md**

Document prerequisites, included tools, fresh installation, current account migration, updates, garbage collection, rollback, and root recovery. The first clone must use temporary Git:

~~~bash
nix-shell --extra-experimental-features 'nix-command flakes' -p git \
  --run 'git clone https://github.com/Itterum/nixos-config.git ~/nixos-config'
cd ~/nixos-config
sudo nixos-rebuild switch --flake path:.#wsl \
  --extra-experimental-features 'nix-command flakes'
~~~

Document the required one-time Windows command wsl.exe --terminate NixOS and recovery through wsl.exe -d NixOS -u root.

- [ ] **Step 2: Verify and commit documentation**

~~~bash
bash tests/configuration.sh
nix flake check path:. --no-build
git add README.md docs/superpowers/plans/2026-09-03-wsl-cli-implementation.md
git commit -m "document WSL installation and recovery"
~~~

Expected: checks pass and the worktree is clean.

---

### Task 4: Migrate and activate the current WSL

**Files:**
- Move: /home/nixos to /home/itterum
- Back up: /etc/nixos to /root/nixos-backup-<UTC timestamp>
- Replace: the active NixOS generation with the built wsl configuration

**Interfaces:**
- Consumes: the built .#wsl closure and existing UID 1000 account.
- Produces: active user itterum and source tree /home/itterum/nixos-config.

- [ ] **Step 1: Back up and record current state**

Record id nixos and the current generation. Recursively copy /etc/nixos into a dated root-owned recovery directory and print its path.

- [ ] **Step 2: Rename the account**

Run usermod --login itterum nixos, followed by usermod --home /home/itterum --move-home itterum. Verify id itterum reports UID 1000 and the repository moved with the home.

- [ ] **Step 3: Activate**

~~~bash
sudo nixos-rebuild switch \
  --flake path:/home/itterum/nixos-config#wsl \
  --extra-experimental-features 'nix-command flakes'
~~~

Confirm /etc/wsl.conf selects itterum and the current generation changed.

- [ ] **Step 4: Check repository state**

Confirm the commit list, branch, and divergence without pushing.

---

### Task 5: Restart and verify the live environment

**Files:**
- None.

**Interfaces:**
- Consumes: the activated WSL generation.
- Produces: final evidence.

- [ ] **Step 1: Restart from Windows**

Run wsl.exe --terminate NixOS and start a new NixOS command.

- [ ] **Step 2: Verify identity and system**

Confirm whoami itterum, UID 1000, /home/itterum, Zsh, hostname nixos-wsl, running systemd, and no failed units.

- [ ] **Step 3: Verify tools**

Confirm Git, gh, Helix, Zsh, Starship, direnv, rg, fd, fzf, zoxide, bat, eza, btop, tmux, jq, uv, kubectl, k9s, teleport, codex, podman, and docker exist. Confirm distrobox is absent and rootless podman info succeeds.

- [ ] **Step 4: Run final repository checks**

~~~bash
cd ~/nixos-config
bash tests/configuration.sh
nix flake check path:. --no-build
git status --short --branch
~~~

Expected: checks pass; the branch is clean and ahead of origin/main until pushed.


---

### Task 4A: Finish GitHub SSH setup

**Files:**
- Copy: `C:\Users\itterum\.ssh\id_ed25519` to `/home/itterum/.ssh/id_ed25519`
- Copy: `C:\Users\itterum\.ssh\id_ed25519.pub` to `/home/itterum/.ssh/id_ed25519.pub`

**Interfaces:**
- Consumes: the user-authorized Windows Ed25519 key pair and system OpenSSH client.
- Produces: GitHub SSH access for the migrated Linux account.

- [ ] **Step 1: Preserve secure permissions**

Set `/home/itterum/.ssh` to 0700, the private key to 0600, and the public key to
0644. Compare the copied public-key fingerprint with the Windows source without
printing private key contents.

- [ ] **Step 2: Verify GitHub and update origin**

Run `ssh -T git@github.com` and accept the documented successful-authentication
response, which intentionally exits nonzero because GitHub provides no shell.
Set `origin` to `git@github.com:Itterum/nixos-config.git` and verify it with
`git ls-remote origin HEAD`.

## Execution clarification: fresh installations

The README's fresh-install path must build before activation. It then restarts
WSL as root, renames the existing `nixos` UID 1000 account to `itterum`, moves
its home, and activates the already validated flake. A direct first switch is
excluded because the initial account already owns UID 1000.
