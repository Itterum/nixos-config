# itterum NixOS configuration

The flake defines two NixOS hosts:

| Host | Hostname | Power profile | Graphics |
| --- | --- | --- | --- |
| `laptop` | `nixos` | TLP | default/iGPU drivers |
| `desktop` | `desktop` | default desktop policy | NVIDIA RTX 5060, open kernel module |

Both hosts share Limine and the `Windows Boot Manager` EFI entry. Home Manager
uses the same user configuration on both systems.

## Repository layout

- `hosts/` contains only host-specific composition and generated hardware data.
- `profiles/` defines the shared NixOS and Home Manager workstation profiles.
- `modules/nixos/` contains reusable system, desktop, hardware, network,
  program and virtualisation modules.
- `modules/home/` contains reusable desktop, shell and user-program modules.
  Larger configurations such as Niri and Helix are split into focused files.
- `home/itterum/` is the user entry point that selects a Home Manager profile.
- `assets/` contains declaratively installed resources such as wallpapers.
- `experiments/` contains prototypes that are intentionally not imported by
  either production profile.
- `tests/` contains evaluation-based regression checks for both hosts.

## Checks

```bash
bash tests/configuration.sh
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
in Git. Disable Secure Boot for the initial installation unless you separately
configure a signed-boot solution such as Lanzaboote.

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

## Declarative desktop settings

Niri is configured entirely through `programs.niri.settings`; there is no
maintained `config.kdl` in the repository. The Nix modules under
`modules/home/desktop/niri/` generate and validate the final KDL configuration.

Wayle is the active desktop shell and notification provider. Its wallpaper is
installed from `assets/wallpapers/nix-wallpaper.png` into the user's managed
Home Manager files. Mako and DMS are disabled, and no DMS configuration assets
are kept in the active user configuration.

The QML prototype under `experiments/itterum-shell/` is deliberately
disconnected from the flake. Moving an idea into production requires an
explicit import from a profile or one of its modules.
