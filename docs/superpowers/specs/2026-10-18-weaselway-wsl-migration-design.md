# Weaselway WSL Migration Design

## Context

The repository currently defines a physical `pc` host with disk UUIDs, an
NVIDIA driver, Limine Secure Boot, SDDM, gaming, Sunshine, and desktop
applications. The system running the repository is instead the Weaselway
Plasma image on NixOS-WSL 26.05. Its `/etc/nixos` flake composes NixOS-WSL,
the Weaselway graphics module, the Weaselway image helper, and a small local
configuration.

The installed system uses `nixos` as its only normal user, with UID 1000 and
home `/home/nixos`. Weaselway starts Plasma through `ww-start-session` and a
transient `weaselway-session.service`; it deliberately does not use a display
manager. The repository's Home Manager and Plasma Manager configuration is
currently tied to the former `itterum` user and physical `pc` host.

## Goals

- Make this repository the declarative configuration for the installed
  Weaselway Plasma system.
- Export one host, `nixosConfigurations.nixos`, matching the current hostname.
- Preserve the existing `nixos` user, UID 1000, and `/home/nixos`.
- Preserve Weaselway's patched graphics stack, Windows viewer, input, audio,
  and Plasma session startup.
- Adapt the repository's Plasma Manager appearance and panel configuration to
  Weaselway.
- Keep the shared CLI environment, Helix, GitHub SSH settings, Foot, Brave,
  Zed, and native Docker.
- Remove physical-PC configuration and applications that are not selected for
  the WSL system.
- Produce a configuration that evaluates and builds before it is activated.

## Non-goals

- Renaming the `nixos` user or moving its home directory.
- Managing a physical NixOS host from this flake.
- Using SDDM or another display manager.
- Carrying over Limine, Secure Boot, disk UUIDs, NVIDIA configuration,
  Sunshine, Steam, JetBrains tools, Chrome, ChatGPT, Flatpak, or Caffeine.
- Enabling Docker Desktop integration.
- Automatically activating the new generation during implementation.

## Flake and Host Architecture

`weaselway` becomes the authoritative upstream input for its matching
`nixpkgs`, NixOS-WSL module, patched Mesa and KWin, dxgdrm support, Windows
viewer, and binary cache settings. The top-level `nixpkgs` input follows
`weaselway/nixpkgs`; Home Manager follows that alias, and Plasma Manager
follows Home Manager and the same nixpkgs so that all layers use one package
set.

The flake keeps the existing flake-parts and import-tree module layout and
exports only `nixosConfigurations.nixos`. That configuration is built with
`weaselway.inputs.nixpkgs.lib.nixosSystem` and imports:

- `weaselway.inputs.nixos-wsl.nixosModules.default`;
- `weaselway.nixosModules.weaselway`;
- the local WSL host module.

The repository does not import `weaselway.nixosModules.image`. That module is
an image bootstrap helper whose only purpose is to create an initial
`/etc/nixos/flake.lock`; this repository already owns and updates its lock
file.

The `modules/hosts/pc` profile is removed. Its boot loader, filesystems,
storage, NVIDIA, Sunshine, gaming, SDDM, and hardware-specific settings must
not remain reachable from the WSL configuration. Inputs used only by removed
features are removed as well.

## WSL and Weaselway System Configuration

The local host module preserves the effective settings from the installed
`/etc/nixos/configuration.nix`:

- platform `x86_64-linux`;
- `wsl.enable = true` and `wsl.defaultUser = "nixos"`;
- `weaselway.enable = true` and `weaselway.session = "plasma"`;
- Plasma 6 enabled with SDDM disabled;
- the image's reduced Plasma package set;
- KDE PIM, fwupd, Orca, and Speech Dispatcher disabled;
- Nix channels disabled and flakes enabled;
- Git and `nix-ld` enabled;
- `system.stateVersion = "26.05"`.

The plaintext image password is not copied into the repository. NixOS keeps
mutable users by default, so switching to the new generation preserves the
existing password. Weaselway continues adding the `render`, `video`, and
`input` groups required by its graphics and input services.

Native Docker is enabled with `virtualisation.docker.enable = true`, and
`nixos` is added to the `docker` group. Docker Desktop integration is not
enabled.

## Home Manager and Applications

The shared Home Manager baseline is renamed and updated from `itterum` to
`nixos`, with `home.homeDirectory = "/home/nixos"`. It retains the existing
CLI packages and shell configuration, Git identity, GitHub CLI, Starship,
direnv, eza, fzf, zoxide, and NVM setup.

The WSL host imports these user modules:

- Helix and its language tooling;
- GitHub SSH configuration;
- Plasma Manager configuration;
- Foot terminal configuration;
- Zed and its existing settings.

Brave is installed as a system package. Foot remains the configured Plasma
terminal, and Konsole is excluded. The configuration does not import the old
desktop-apps module because it also enables Flatpak and several applications
outside the approved scope.

## KDE Adaptation

Plasma Manager retains the Nix wallpaper, WhiteSur icon and cursor themes,
Kpple Menu, the top panel, and the centered floating bottom dock.

The bottom dock contains only launchers provided by the resulting system:

1. Dolphin;
2. Foot;
3. Brave;
4. Zed.

The Kpple Menu keeps About This Computer, System Settings, Lock Screen, and
Log Out. The Plasma Discover entry is removed because Discover is not
installed. Restart and Shut Down entries are removed because they target a
normal machine lifecycle rather than a Weaselway session inside WSL.

No SDDM theme is built or configured. Weaselway remains the sole owner of
session startup, graphics-driver integration, audio transport, viewer
services, and the required WSL workarounds.

## Tests and Validation

Repository tests are rewritten around `nixosConfigurations.nixos` and the
`nixos` Home Manager user. Evaluation tests cover:

- WSL, Weaselway, Plasma, and the Plasma session selection;
- disabled SDDM and absence of physical-host boot settings and disk UUIDs;
- default-user identity, UID, home directory, and required groups;
- native Docker enablement;
- Brave, Foot, and Zed availability;
- Home Manager's CLI, Helix, GitHub SSH, and Zed composition;
- wallpaper, WhiteSur themes, Kpple Menu, and the exact dock launchers;
- the reduced Weaselway Plasma package policy.

Validation runs the formatter, all repository tests, `nix flake check`, and a
full build of
`nixosConfigurations.nixos.config.system.build.toplevel`. The implementation
does not call `nixos-rebuild switch`.

## Activation and Recovery

After reviewing the successful build, the user can activate it with:

```bash
sudo nixos-rebuild switch --flake .#nixos
```

The Plasma session must then be restarted with `ww-start-session stop` followed
by `ww-start-session`. Runtime verification checks `weaselway-prep.service`,
`weaselway-session.service`, the user `weaselwayd.service`, Plasma, Docker,
Brave, and Zed. If activation regresses the desktop, the previous NixOS
generation remains available through `nixos-rebuild switch --rollback`; a
kernel-module change instead requires `wsl --shutdown` from Windows before
starting the distribution again.

## Expected Repository Changes

- Update `flake.nix` and `flake.lock` around the Weaselway package set.
- Replace `modules/hosts/pc` with one WSL/Weaselway host profile.
- Rename and adapt `home/itterum.nix` for `nixos`.
- Adapt the KDE panel and Kpple Menu configuration.
- Reuse the existing Helix, GitHub, Foot, and Zed modules.
- Remove feature modules and inputs that become unreachable.
- Replace physical-PC tests with Weaselway/WSL and adapted KDE tests.
- Keep historical design and plan documents unchanged as project history.
