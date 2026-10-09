# NixOS System Menu Design

## Goal

Replace the application launcher at the left edge of the Plasma top panel with a compact, macOS-style system menu. The button uses the existing NixOS snowflake icon, while the adjacent KDE global menu remains unchanged.

## Selected Widget

Use SCP Menu Reborn for Plasma 6.6+, pinned to upstream commit `0f90c0fabd171167c7bf5555cf8cbb12e98295fe`. Its Plasma plugin ID is `org.kde.plasma.scpmr`.

The widget source is fetched with a fixed Nix hash and installed as an immutable package under `share/plasma/plasmoids/org.kde.plasma.scpmr`. The package is added through the existing KDE Home Manager module; installation through KDE Store or mutable files under `~/.local` is out of scope.

## Menu Contents

The top panel replaces `org.kde.plasma.kickoff` with `org.kde.plasma.scpmr`. The widget uses the `nix-snowflake` icon and exposes only:

- About This System, backed by `org.kde.kinfocenter.desktop`;
- System Settings, backed by `systemsettings.desktop`;
- Lock Screen;
- Log Out;
- Restart;
- Shut Down.

Sleep and Hibernate are explicitly disabled. No general application list or additional launcher shortcuts are shown.

The top panel order is:

1. NixOS system menu;
2. KDE global menu for the active application;
3. flexible spacer;
4. system tray;
5. clock.

The bottom dock and all other Plasma settings remain unchanged.

## Configuration Ownership

`home/kde/default.nix` continues to own panel composition. A focused Nix helper in the same KDE module packages the pinned plasmoid and supplies its configuration. This avoids introducing another feature module for a component used exclusively by the KDE panel.

The menu action order and enabled state are encoded as JSON strings because that is the widget's published KConfig interface. The app entries use stable desktop-file IDs already present in the Plasma system closure.

## Verification

Automated evaluation must assert that:

- the widget package is present in the Home Manager package set;
- the top panel contains `org.kde.plasma.scpmr` and no longer contains Kickoff;
- the icon is `nix-snowflake`;
- the only app entries are About This System and System Settings;
- Lock, Log Out, Restart, and Shut Down are enabled;
- Sleep and Hibernate are disabled;
- the adjacent global-menu widget and bottom dock are preserved;
- the complete `pc` system closure builds.

After activation, Plasma Shell must remain active and its generated panel configuration must reference `org.kde.plasma.scpmr`. If the widget fails to load, the previous NixOS generation and the prior Git commit remain the rollback paths.
