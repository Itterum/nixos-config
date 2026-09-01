# itterum NixOS configuration

The flake defines two NixOS hosts:

| Host | Hostname | Power profile | Graphics |
| --- | --- | --- | --- |
| `laptop` | `nixos` | TLP with its power-profiles interface | default/iGPU drivers |
| `desktop` | `desktop` | power-profiles-daemon | NVIDIA RTX 5060, open kernel module |

Both hosts share Limine and the `Windows Boot Manager` EFI entry. Home Manager
uses the same user configuration on both systems.

## Repository layout

- `hosts/` contains only host-specific composition and generated hardware data.
- `profiles/` defines the shared NixOS and Home Manager workstation profiles.
- `modules/nixos/` contains reusable system, desktop, hardware, network,
  program and virtualisation modules.
- `modules/home/` contains reusable shell and user-program modules. Larger
  configurations such as Helix are split into focused files.
- `home/itterum/` is the user entry point that selects a Home Manager profile.
- `assets/` contains repository resources such as wallpapers; a module must
  reference an asset before Nix installs it.

## Checks

```bash
nix flake check path:. --no-build
nix build --no-link 'path:.#nixosConfigurations.laptop.config.system.build.toplevel'
nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'
```

Use the `path:` form while newly created files are not yet tracked by Git.

## Installing the desktop

`hosts/desktop/hardware-configuration.nix` in the repository is deliberately a
minimal bootstrap file. Its root filesystem points to the intentionally absent
label `REPLACE_ME_DESKTOP_ROOT`; it does not contain real disk UUIDs, initrd
storage drivers or CPU firmware settings and cannot be used for the real
installation. The related evaluation warning is expected until the scan is
replaced.

From the NixOS installer, first partition the disks and mount the target root at
`/mnt`. Mount the EFI system partition at `/mnt/boot`; this is required by the
shared Limine configuration. Then generate the hardware scan into a temporary
directory and replace the bootstrap file:

```bash
config_repo=/mnt/etc/nixos-config
generated_config=/tmp/nixos-generated

git clone <your-repository-url> "$config_repo"
sudo nixos-generate-config --root /mnt --dir "$generated_config"
sudo install -m 0644 \
  "$generated_config/hardware-configuration.nix" \
  "$config_repo/hosts/desktop/hardware-configuration.nix"

cd "$config_repo"
nix flake check path:. --no-build
sudo nixos-install --flake 'path:.#desktop'
sudo nixos-enter --root /mnt -c 'passwd itterum'
```

The last command sets the login password for the declaratively created user;
the configuration intentionally does not store a plaintext or hashed password
in Git.

Limine Secure Boot is enabled for both hosts. The target system must already
have sbctl keys under `/var/lib/sbctl`; otherwise bootloader installation stops
before writing an unsigned EFI binary. Preserve the enrolled desktop keys when
reinstalling and verify them with `sbctl status` before the first rebuild.

Inspect the generated file before installation. It must contain at least the
real `fileSystems."/"`, `/boot`, storage-related initrd modules, host platform
and the appropriate AMD or Intel CPU microcode option. Do not copy the laptop
hardware file because its filesystem and swap UUIDs belong to another machine.

The RTX 5060 configuration lives only in
`modules/nixos/hardware/nvidia.nix`. PRIME is intentionally absent because this
desktop has no hybrid graphics. GPU access inside Podman containers is also not
enabled; add
`hardware.nvidia-container-toolkit.enable = true` only if CUDA/container GPU
workloads are needed.

## COSMIC desktop

The native NixOS COSMIC module provides the desktop, Xwayland support, portals
and the `cosmic-greeter` login screen. `system76-scheduler` is enabled for its
process-priority rules; it does not require System76 hardware. The
`system76-power` hardware daemon is intentionally not enabled.

On the laptop, TLP manages power and `tlp-pd` exposes the power-profiles API
used by COSMIC, while the standalone `power-profiles-daemon` remains disabled
to avoid a conflict. The desktop uses the standalone daemon selected by the
COSMIC NixOS module.

COSMIC user preferences are currently mutable state under `~/.config/cosmic`;
Home Manager does not yet manage them in this repository.
