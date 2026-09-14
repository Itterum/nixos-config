# Itterum NixOS workstation

This flake defines a portable physical NixOS workstation named `desktop`. It uses Niri and a small fallback desktop while Itterum Shell is being adapted from its Omarchy and Hyprland origins.

## Current desktop

- Niri Wayland compositor
- greetd with tuigreet
- Waybar, Fuzzel, Mako, swaybg, swaylock, and swayidle
- PipeWire and WirePlumber
- NetworkManager and Bluetooth
- XDG portals, polkit, GNOME Keyring, udisks2, gvfs, and upower
- Home Manager for the `itterum` user
- Ghostty, Firefox, Nautilus, KeePassXC, Telegram Desktop, Obsidian, Helix, and CLI development tools

`itterum-shell` is retained as a Git submodule and local flake input, but it is not installed or started. Its current code still assumes Omarchy and Hyprland. The fallback components keep this configuration usable while the shell gains a package, a Niri adapter, and a Home Manager module.

## Layout

- `hosts/desktop/` contains host composition, boot policy, and the replaceable hardware scan.
- `profiles/` composes reusable NixOS and Home Manager modules.
- `modules/nixos/` configures system services.
- `modules/home/` configures the user environment and Niri.
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
