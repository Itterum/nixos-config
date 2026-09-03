# Portable NixOS-WSL CLI Configuration Design

## Goal

Convert the repository into a compact, reproducible configuration for one
NixOS-WSL system. The configuration must migrate the current `nixos` account to
`itterum`, preserve UID 1000, provide a complete command-line development
environment, and be reusable after a clean NixOS-WSL import or on another
Windows computer.

## Repository scope

The repository will support one flake output,
`nixosConfigurations.wsl`. Physical desktop and laptop hosts, graphical
desktop modules, graphical applications, wallpapers, prototypes, and their
flake inputs will be removed.

The maintained runtime files will be:

- `flake.nix`: pins Nixpkgs, NixOS-WSL, and Home Manager and assembles the WSL
  configuration.
- `configuration.nix`: contains system, WSL, account, Nix, and Podman settings.
- `home.nix`: contains the user's shell and command-line programs.
- `helix.nix`: contains Helix editor and language-server settings.
- `README.md`: documents first installation, migration, normal updates, and
  recovery.
- `tests/configuration.sh`: evaluates the important invariants without relying
  on the currently active system.

This design document is retained as the rationale for the compact layout.

## Flake and system configuration

The flake will use NixOS 26.05, the corresponding Home Manager release, and a
locked NixOS-WSL input. The standalone Codex, Niri, Noctalia, Herdr, and agent
inputs will be removed. Codex CLI will come from Nixpkgs.

The WSL system will:

- use hostname `nixos-wsl`;
- enable the NixOS-WSL module and set `wsl.defaultUser = "itterum"`;
- preserve `system.stateVersion = "25.05"`, matching the system's first active
  flake configuration;
- declare `itterum` as UID 1000, a member of `wheel`, with Zsh as the login
  shell;
- allow passwordless sudo for the WSL administrative user so a fresh system
  remains manageable before a password is configured;
- enable flakes, `nix-command`, automatic store optimisation, and weekly
  garbage collection;
- enable `nix-ld` for development tools that expect a conventional Linux
  dynamic loader;
- enable rootless Podman and its Docker-compatible command;
- keep a small system-level recovery set: Git, curl, wget, and Vim.

No display manager, compositor, graphical shell, audio stack, desktop portal,
Bluetooth service, graphical application, or WSLg-specific application will be
configured.

## Home Manager environment

Home Manager will manage `/home/itterum` with `home.stateVersion = "26.05"`.
It will configure:

- Zsh completion, autosuggestions, syntax highlighting, and case-insensitive
  completion;
- Starship, direnv with nix-direnv, Git, GitHub CLI, tmux, btop, bat, eza, fzf,
  and zoxide;
- ripgrep, fd, tree, jq, fastfetch, uv, kubectl, k9s, Teleport, Nix formatter,
  and Codex CLI;
- Helix as the default editor, with the existing language support and formatters
  for TypeScript/JavaScript, Rust, Python, C#, Nix, QML, JSON, TOML, Markdown,
  Bash, and KDL.

Distrobox and all graphical packages are excluded.

## Migration of the current WSL instance

Before changing the account, the new flake will be evaluated and its system
closure built. The existing `/etc/nixos` configuration will be copied to a
dated root-owned recovery directory.

The account will then be renamed from `nixos` to `itterum`, retaining UID 1000,
and `/home/nixos` will move to `/home/itterum`. The repository will live at
`/home/itterum/nixos-config`. The prebuilt configuration will be activated from
that path, making `itterum` the WSL default user. Windows will terminate and
restart the distribution once so the new default user and environment take
effect.

If activation fails after the account rename, recovery remains available with
`wsl.exe -d NixOS -u root` and the previous NixOS generation.

## Fresh installation and portability

The README will start from an already imported official NixOS-WSL distribution.
The bootstrap uses a temporary Git from `nix-shell`, clones this repository into
the Linux filesystem, and runs `nixos-rebuild switch --flake .#wsl` with flake
features supplied on the first invocation. After WSL is restarted, the default
account is `itterum` and subsequent rebuilds use the declaratively installed
tools.

The configuration contains no machine-specific disk identifiers, GPU settings,
Windows paths, secrets, or mutable generated hardware configuration, so the same
flake can be applied to another x86_64 NixOS-WSL instance.

## Validation

Automated evaluation will verify the flake exposes only `wsl`, UID 1000 and the
default user are `itterum`, the preserved state versions are correct, Podman is
enabled without Distrobox, expected CLI programs are present, and desktop
services and packages are absent.

Before activation, the workflow will run the regression script, `nix flake
check`, and build `nixosConfigurations.wsl.config.system.build.toplevel`.
After activation and WSL restart, it will verify identity, home directory,
default shell, system health, flake settings, core commands, Podman, and Home
Manager state.

## SSH migration amendment

The Windows Ed25519 key pair from `C:\Users\itterum\.ssh` will be copied into
`/home/itterum/.ssh` without printing private key material. The directory and
private/public files will use modes 0700, 0600, and 0644 respectively. OpenSSH
will be part of the system recovery tools. After the account migration, GitHub
SSH authentication will be verified and this repository's `origin` will use
`git@github.com:Itterum/nixos-config.git`.

## Fresh-install UID migration clarification

A fresh official NixOS-WSL image already has the `nixos` account at UID 1000.
The portable procedure therefore builds the new closure first, restarts the
distribution under root, renames that existing account and moves its home, and
only then activates the new flake. This avoids two accounts competing for UID
1000 during activation.
