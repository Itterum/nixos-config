# itterum NixOS configuration

The flake defines one NixOS host:

| Host | Hostname | Power profile | Graphics |
| --- | --- | --- | --- |
| `desktop` | `desktop` | default desktop policy | NVIDIA RTX 5060, open kernel module |

The desktop uses Limine with the `Windows Boot Manager` EFI entry. Home Manager
configures the `itterum` user.

## Repository layout

- `hosts/` contains only host-specific composition and generated hardware data.
- `profiles/` defines the shared NixOS and Home Manager workstation profiles.
- `modules/nixos/` contains reusable system, desktop, hardware, network,
  program and virtualisation modules.
- `modules/home/` contains reusable desktop, shell and user-program modules.
  Larger configurations such as Niri and Helix are split into focused files.
- `home/itterum/` is the user entry point that selects a Home Manager profile.
- `assets/` contains declaratively installed resources such as wallpapers.
- `tests/` contains evaluation-based regression checks for the desktop host.

## Checks

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
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
desktop Limine configuration. Then generate the hardware scan into a temporary
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
and the appropriate AMD or Intel CPU microcode option. Do not reuse a hardware
scan from another machine because its filesystem and swap UUIDs will differ.

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

Noctalia Greeter is the graphical `greetd` frontend and offers Niri as the
default session. Automatic login is disabled, so every new graphical session
starts with authentication in the greeter.

Noctalia is the active desktop shell, launcher, notification provider,
wallpaper engine, lock screen and idle manager. It runs as a Home Manager
systemd user service, and Niri key bindings control it through `noctalia msg`.
The wallpaper is installed from `assets/wallpapers/nix-wallpaper.png` into the
user's managed Home Manager files. Wayle, AnyRun, Fuzzel, swayidle, gtklock,
Mako and DMS are disabled.
