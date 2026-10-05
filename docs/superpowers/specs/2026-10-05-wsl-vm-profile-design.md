# VM and WSL Profile Design

## Context

This flake currently defines graphical VMware profiles and a shared Home
Manager configuration for `itterum`. The new `modules/hosts/wsl` directory is
an uncommitted copy of the VM profile, so it still contains a bootloader, disk
UUIDs, NetworkManager, audio, printing, Flatpak, and desktop-oriented settings
that do not belong in WSL.

The installed NixOS-WSL distribution currently starts as `nixos`. Its home is
small and contains the configuration repository, Helix configuration, and SSH
files. The target state uses `itterum` as the default WSL user while retaining
the old `nixos` account and home as a recovery path.

## Goals

- Keep graphical VM configurations for GNOME and KDE.
- Add a valid headless `wsl` NixOS configuration.
- Share one Home Manager CLI baseline between VM and WSL.
- Keep graphical applications and desktop services out of WSL.
- Run a native Docker daemon inside NixOS-WSL without Docker Desktop.
- Change the default WSL user to `itterum` safely.
- Copy persistent user data to `/home/itterum` without deleting the original.
- Verify evaluation, activation, user migration, CLI tools, and Docker.

## Non-goals

- Removing the `nixos` account or `/home/nixos`.
- Installing a graphical desktop or WSLg applications in the WSL profile.
- Enabling Docker Desktop integration, Kubernetes, GPU containers, or rootless
  Docker.
- Refactoring all shared NixOS settings into a new abstraction.
- Changing the existing VM hardware configuration or desktop selection.

## Architecture

### Flake inputs and outputs

Add a `nixos-wsl` input pinned to `release-26.05` and make its `nixpkgs` input
follow this flake's `nixpkgs`. The release branch exists and matches the
flake's NixOS 26.05 channel.

Export one new configuration:

- `vm`, `vm-gnome`, and `vm-kde` remain graphical VM configurations.
- `wsl` becomes the headless NixOS-WSL configuration.

The `wsl` output imports the official `nixos-wsl.nixosModules.default` module
and the local WSL configuration module. It never imports VM hardware or desktop
modules.

### Shared user environment

`home/itterum.nix` remains the shared CLI baseline. It supplies the current
terminal tools and shell programs, including Git, GitHub CLI, Helix-related
workflow tools, Starship, direnv, eza, fzf, and zoxide.

Host composition remains explicit:

- VM imports the shared user baseline, Helix, Zed, and its chosen desktop
  module.
- WSL imports the shared user baseline and Helix only.

No additional common system module will be introduced yet. The small amount of
Home Manager wiring duplicated between the host modules is easier to understand
than another abstraction at the current repository size.

### WSL system configuration

The WSL profile will:

- enable Nix flakes and `nix-command`;
- enable NixOS-WSL and set `wsl.defaultUser = "itterum"`;
- use hostname `nixos-wsl`;
- set the local timezone to `Europe/Minsk`;
- connect Home Manager as a NixOS module with global packages and user
  packages enabled;
- manage `/home/itterum` through the existing Home Manager configuration;
- retain Windows executable interoperability and `/mnt` automount defaults;
- enable `programs.nix-ld` for common remote-development tooling;
- enable native Docker with `virtualisation.docker.enable = true`;
- add `itterum` to the `docker` group in addition to groups supplied by the
  NixOS-WSL user module;
- keep `system.stateVersion = "26.05"`.

The WSL profile will not contain a bootloader, filesystem declarations, swap
devices, VM kernel modules, NetworkManager, XKB, printing, PipeWire, Flatpak,
Firefox, Zed, ChatGPT, GNOME, or KDE. The copied WSL `hardware.nix` file will be
removed because WSL hardware is owned by the NixOS-WSL module.

## User and Data Migration

Changing the default user on an already installed NixOS-WSL system must use a
boot generation rather than an in-place switch:

1. Evaluate and build the new `wsl` flake output while logged in as `nixos`.
2. Apply it with `sudo nixos-rebuild boot --flake .#wsl`.
3. Exit WSL and terminate only the `NixOS` distribution from PowerShell.
4. Run one root session and exit immediately so WSL applies the new generation.
5. Terminate the distribution again and reopen it normally.
6. Verify the default login is `itterum` before copying data.

Data migration happens after Home Manager has created the destination home.
The migration copies, rather than moves, the repository and persistent SSH
files from `/home/nixos`, preserves modes, changes ownership to
`itterum:users`, and refuses to overwrite destination files silently.

The current Home Manager-managed `.config/helix` directory is regenerated from
the flake instead of copied. `/home/nixos/.cache` is not migrated. The original
home and user remain intact for rollback.

## Validation

Before activation:

- format the Nix files;
- run `nix flake check`;
- evaluate or build both `.#nixosConfigurations.vm.config.system.build.toplevel`
  and `.#nixosConfigurations.wsl.config.system.build.toplevel`;
- confirm the WSL closure does not enable desktop, display-manager, printing,
  audio, Flatpak, or VM boot/filesystem settings.

After activation and WSL restart:

- `whoami` returns `itterum`;
- the home directory is `/home/itterum` and has correct ownership;
- the old `nixos` account and `/home/nixos` still exist;
- `git`, `gh`, `hx`, `rg`, `fd`, `jq`, `uv`, `kubectl`, and `k9s` resolve;
- `systemctl is-active docker` returns `active`;
- `docker run --rm hello-world` succeeds;
- the migrated repository and SSH files exist with no private key content
  printed during verification.

VM verification remains separate: successful WSL activation does not prove the
VM profiles build or boot. A successful evaluation/build of each target is
required before calling the configuration complete.

## Failure and Recovery

- If evaluation or build fails, do not activate the generation.
- If the new default login fails, enter with `wsl -d NixOS --user root` and
  select the previous system generation or correct `wsl.defaultUser`.
- If data copying encounters a destination conflict, stop and review that path;
  do not overwrite it automatically.
- If Docker fails, inspect the native `docker.service`; do not enable Docker
  Desktop as an implicit fallback.
- Do not delete `/home/nixos` until the user explicitly requests it after the
  new profile has been used successfully.

## Expected File Changes

- Modify `flake.nix` to add the NixOS-WSL input.
- Update `flake.lock` for that input.
- Rewrite `modules/hosts/wsl/default.nix` to export only the `wsl` system.
- Rewrite `modules/hosts/wsl/configuration.nix` as a WSL-specific module.
- Remove `modules/hosts/wsl/hardware.nix`.
- Leave VM and shared Home Manager files unchanged unless evaluation exposes a
  compatibility issue directly caused by the new profile.
