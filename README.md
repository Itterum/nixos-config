# Itterum NixOS workstation

This flake defines a portable physical NixOS workstation named `desktop`. It uses Hyprland through UWSM and runs the declarative Itterum Shell as a supervised Home Manager service.

## Current desktop

- Hyprland Wayland compositor managed by UWSM
- greetd with tuigreet
- Itterum Shell bar, installed-app launcher, and core desktop surfaces
- Fuzzel and swaylock retained as manual recovery tools; swaybg owns the wallpaper
- PipeWire and WirePlumber
- NetworkManager and Bluetooth
- XDG portals, polkit, GNOME Keyring, udisks2, gvfs, and upower
- Home Manager for the `itterum` user and the shell user service
- Ghostty, Firefox, Nautilus, KeePassXC, Telegram Desktop, Obsidian, Helix, and CLI development tools

`itterum-shell` is a Git submodule and local flake input. Hyprland-specific behavior is isolated behind its compositor facade so a Niri backend can be added later without coupling ordinary UI code to either compositor.

## Layout

- `hosts/desktop/` contains host composition, boot policy, and the replaceable hardware scan.
- `profiles/` composes reusable NixOS and Home Manager modules.
- `modules/nixos/` configures system services.
- `modules/home/` configures the user environment, Hyprland, and Itterum Shell.
- `home/itterum/` is the Home Manager entry point.
- `tests/configuration.sh` evaluates portable regression invariants.
- `assets/` contains managed resources such as the wallpaper.

## Validate from another Linux distribution

The official multi-user Nix installation with flakes enabled can evaluate and build the configuration without running NixOS:

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
nix build --no-link \
  path:.#nixosConfigurations.desktop.config.system.build.toplevel
```

Use `path:.` so untracked files are included while reviewing local changes.

The build is read-only with respect to the running Omarchy session: it evaluates and builds a NixOS closure but does not activate it. Graphical test and recovery commands are documented in [`docs/testing/hyprland-shell-core.md`](docs/testing/hyprland-shell-core.md).

## Hardware placeholder

`hosts/desktop/hardware-configuration.nix` deliberately points `/` at the nonexistent label `REPLACE_ME_DESKTOP_ROOT`. This makes evaluation and builds possible, but it is not safe to install as-is.

From the NixOS installer, partition the target, mount its root at `/mnt`, and mount the EFI system partition at `/mnt/boot`. Clone this repository including its submodule, then replace the placeholder:

```bash
sudo nixos-generate-config --root /mnt --dir /tmp/nixos-generated
sudo install -m 0644 \
  /tmp/nixos-generated/hardware-configuration.nix \
  ./hosts/desktop/hardware-configuration.nix
```

Inspect the generated file. It must contain the actual root and `/boot` filesystems, storage-related initrd modules, CPU firmware settings, and any swap devices. Add GPU-specific configuration only after the target hardware is known.

## Install

After replacing the hardware file:

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
sudo nixos-install --flake path:.#desktop
sudo nixos-enter --root /mnt -c 'passwd itterum'
```

The boot policy assumes a UEFI machine and uses systemd-boot. Secure Boot enrollment and dual-boot entries are intentionally not configured.

## Rebuild and recovery

On the installed system:

```bash
sudo nixos-rebuild switch --flake path:.#desktop
sudo nixos-rebuild list-generations
sudo nixos-rebuild switch --rollback
```

Store maintenance remains explicit:

```bash
sudo nix-collect-garbage --delete-older-than 14d
nix store optimise
```

Do not change `system.stateVersion` or `home.stateVersion` after the first installation merely to match a newer channel. Both are currently `26.05` for a fresh NixOS 26.05 system.
