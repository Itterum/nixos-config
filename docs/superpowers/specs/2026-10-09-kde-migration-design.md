# KDE Plasma Migration Design

## Goal

Replace GNOME and GDM completely on the `pc` profile with a clean, standard KDE Plasma 6 desktop running on Wayland through SDDM. Preserve the existing workstation services, applications, NVIDIA configuration, and keyboard remapping. Use Foot as the only explicitly configured terminal.

The migration is developed on `codex/kde-migration`; `main` remains the stable GNOME configuration until the Plasma installation is verified after reboot.

## Desktop Architecture

Add a focused `pcKde` NixOS module under `modules/hosts/pc/`. It will:

- enable Plasma 6;
- enable SDDM and its Wayland compositor;
- select the Plasma Wayland session by default;
- enable Foot;
- exclude Konsole from Plasma's default package set.

The `pc` host imports `pcKde` alongside its existing hardware and feature modules. GNOME and GDM are removed rather than retained as alternative sessions.

No Plasma customization framework is added during this migration. Plasma starts with its standard layout. Settings made after the migration can be inspected and moved into a dedicated declarative KDE home module in a later change.

## Removed GNOME Configuration

Remove the GNOME Home Manager import from the `pc` user and delete:

- `home/gnome/`, including extensions, dconf settings, and the custom Global Menu package;
- `modules/features/gnome.nix`.

Remove the direct GNOME and GDM options from the host configuration. This also removes the GNOME extensions, panel and dock customization, GNOME clock settings, and the custom NixOS Global Menu icon.

The Caps Lock remapping remains active because `services.xserver.xkb.options = "ctrl:nocaps"` is configured at the system level independently of GNOME.

## Applications

Remove Ptyxis from `pcDesktopApps`. Foot is provided by the new KDE module. Konsole is deliberately excluded so Foot is the single configured terminal.

Keep the existing applications and services unchanged:

- Bazaar and Flatpak with Flathub;
- Brave and Google Chrome;
- KeePassXC;
- JetBrains Toolbox and IDE support;
- Zed and Helix;
- Steam, Protontricks, GE-Proton, and GameMode;
- Docker;
- Sunshine;
- Codex/ChatGPT Desktop;
- SSH/Git configuration and storage automounting.

Dolphin and the standard Plasma utilities come from the Plasma desktop module.

## Activation and Rollback

Build the full `pc` system closure first. Activate it with `nixos-rebuild boot`, not `switch`, so the running GNOME session and current Codex task are not interrupted. The migration becomes active only after the user reboots.

If Plasma cannot start or a critical workflow fails, select the previous NixOS generation from the boot menu. The stable Git configuration remains available on `main` until the migration is explicitly merged.

## Verification

Before reboot:

- format the Nix tree and run `git diff --check`;
- evaluate that Plasma 6, SDDM Wayland, and Foot are enabled;
- evaluate that GNOME and GDM are disabled;
- confirm Konsole is excluded and Ptyxis is absent;
- confirm no active Nix module references the removed GNOME home module;
- build `nixosConfigurations.pc.config.system.build.toplevel`;
- install the generation using `nixos-rebuild boot`.

After reboot:

- confirm the session type is Wayland and the desktop is KDE;
- confirm SDDM is the display manager;
- launch Foot and core desktop applications;
- verify NVIDIA rendering;
- verify Sunshine input/control from the local network;
- verify Steam starts and sees GE-Proton;
- review system and user journals for Plasma, KWin, SDDM, or GPU failures.

Only after these checks pass should `codex/kde-migration` be merged into `main`.
