# Nixarchy migration design

## Goal

Make Nixarchy the only desktop environment in the `nixarchy` branch for both
the `laptop` and `desktop` NixOS configurations. Keep the `cosmic` branch as a
working rollback point and do not switch the running system while preparing the
new configuration.

## Branch strategy

The existing COSMIC configuration is preserved in commit `ecdd5af` on the
`cosmic` branch. All Nixarchy integration work happens on the `nixarchy` branch,
which starts from that commit.

The Nixarchy branch may retain the local COSMIC module as unused source, but the
shared workstation profile must not import it. Switching back to the `cosmic`
branch restores the COSMIC composition without reverting Nixarchy commits.

## Flake integration

Add Nixarchy as a flake input pinned to release `v4.0.1-1` rather than its moving
`main` branch. Import its NixOS module into both configurations through the
shared system composition, and import its Home Manager module for the `itterum`
user through the shared home composition.

Keep Nixarchy's default binary caches enabled. This trusts the Nixarchy and
Hyprland caches and avoids compiling the compositor locally.

## NixOS configuration

Create a focused local NixOS desktop module that:

- imports `inputs.nixarchy.nixosModules.nixarchy`;
- enables `programs.nixarchy`;
- names `itterum` as the desktop user;
- points Nixarchy's apply command at `/home/itterum/nixos-config`;
- leaves Nixarchy's SDDM integration enabled;
- leaves browser policy theming disabled.

Replace the COSMIC import in `profiles/nixos/workstation.nix` with this module.
The change applies equally to `laptop` and `desktop` because both hosts use the
shared workstation profile.

Keep the existing base, audio, Bluetooth, casting, browser, ChatGPT, container,
bootloader, NVIDIA, and laptop power-management modules. On the laptop, TLP
continues managing power. Nixarchy therefore leaves power-profiles-daemon off,
and Omarchy's power-profile command is expected not to work there.

## Home Manager configuration

Create a focused local Home Manager module that imports
`inputs.nixarchy.homeManagerModules.nixarchy` and enables
`programs.nixarchy`. Add it to the shared Home Manager workstation profile.

Keep every existing Home Manager module and setting, including the zsh,
Starship, direnv, Ghostty, Helix, and Zed configurations. Nixarchy may detect
these programs as already installed, but must not replace their declarations or
settings.

## Applications

Keep all existing application declarations, including ChatGPT, Brave, Chrome,
KeePassXC, Telegram, Obsidian, Ghostty, Helix, and Zed. Nixarchy detects known
overlaps and dims their Install rows instead of installing duplicate copies.

Add an imported `nixarchy-apps.nix` at the flake root with an initially empty
Nixarchy application selection. Nixarchy can later copy the user's menu choices
into that file and rebuild the same flake. Application ownership can be moved
to Nixarchy incrementally in later changes; this migration does not remove any
existing application.

## Documentation and operation

Update the repository README to describe Nixarchy as the active desktop in this
branch, explain the generated application-selection file, and document the
post-install verification command. Do not describe COSMIC as active in the
Nixarchy branch.

Preparing the branch must not run `nixos-rebuild switch` or otherwise activate
the new desktop. Activation remains an explicit user action after review.

## Verification

Before declaring the migration ready:

1. Run `nix flake check path:. --no-build`.
2. Build `path:.#nixosConfigurations.laptop.config.system.build.toplevel`
   without creating a result symlink.
3. Build `path:.#nixosConfigurations.desktop.config.system.build.toplevel`
   without creating a result symlink.
4. Confirm the Git worktree contains only the intended Nixarchy changes.

The desktop build may emit the repository's documented warning about its
bootstrap hardware configuration. Any other evaluation or build failure blocks
completion and must be corrected without switching the running system.

After the user activates the configuration and logs into the Nixarchy session,
the user can run `nix run github:olafkfreund/nixarchy#verify` to inspect runtime
graphics, Bluetooth, theme, and shell integration.
