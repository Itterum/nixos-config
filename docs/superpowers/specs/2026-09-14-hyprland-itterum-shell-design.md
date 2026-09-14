# Hyprland-first Itterum Shell design

## Goal

Build the first usable version of the workstation around NixOS, Hyprland, and a focused fork of Omarchy Shell. Preserve the Omarchy shell's visual quality and core desktop interactions while removing its Arch distribution management, application installation, web-app catalog, and public Omarchy command surface.

Hyprland is the first compositor because the current shell already integrates with it. The shell architecture must nevertheless keep compositor-specific behavior behind a narrow boundary so a Niri backend can replace the Hyprland backend later without rewriting the user interface.

## Product decisions

- The first production compositor is Hyprland.
- The shell is based on the real Omarchy Quickshell implementation rather than a visual imitation.
- NixOS and Home Manager are the only owners of installed packages and persistent system configuration.
- The shell does not install, remove, or recommend applications.
- The Omarchy web-app catalog is not included.
- The Omarchy CLI and an Itterum replacement CLI are not part of the first version.
- A small internal helper or daemon is allowed only when a desktop feature cannot be implemented reliably through standard services or Quickshell APIs. It is not a package manager or a user-facing configuration interface.
- The existing fallback desktop remains available during development and is retired component by component only after the shell replacement passes its acceptance checks.

## First-version scope

The first version includes:

- a top bar;
- Hyprland workspaces and active-window state;
- clock;
- system tray as the rightmost item;
- an application launcher that lists only installed desktop entries;
- notifications;
- volume, brightness, and status OSD;
- audio controls;
- network controls;
- Bluetooth controls;
- power and session actions;
- monitor controls;
- session lock;
- idle behavior.

The first version excludes:

- application installation and removal;
- application recommendations and optional-app catalogs;
- web applications created or managed by Omarchy;
- pacman, AUR, Arch update, or Omarchy update integration;
- an update indicator;
- Dropbox and Tailscale panels;
- weather, speed-test, and disk-speed-test panels;
- AI and agent integrations;
- Omarchy provisioning, hardware setup, migrations, and recovery commands;
- user-facing `omarchy` or `ish` commands;
- Niri support in the first activation milestone.

## Ownership boundary

NixOS owns machine-wide capabilities and services, including Hyprland, greetd, NetworkManager, Bluetooth, PipeWire, WirePlumber, polkit, UPower, portals, PAM integration, and the packages required by shell features.

Home Manager owns the user session, the Itterum Shell package and service, shell configuration, theme data, desktop entries, and the explicit application allowlist. Adding an application means editing a Nix list and rebuilding; it never means invoking an installer from the shell.

Itterum Shell owns transient presentation and interaction. It can read standard service state and request narrow runtime actions such as changing volume, connecting to a known network, changing workspace, locking the session, suspending, rebooting, or powering off. It must not mutate the declarative package set or persistent NixOS configuration.

## Repository architecture

The existing `itterum-shell` submodule becomes an installable flake input. It will export at least:

- `packages.<system>.default`, containing the shell QML, required internal helpers, and a stable launcher;
- a development shell for focused shell work;
- optionally a Home Manager module if that reduces duplication without coupling the shell package to this workstation repository.

The workstation repository remains the integration owner. A focused Home Manager module will:

- install the shell package and its declared runtime dependencies;
- generate the shell's user configuration;
- set only the runtime environment required by the package;
- start one Quickshell instance as a systemd user service bound to the graphical session;
- restart the process after unexpected failure with bounded retry behavior;
- avoid starting Waybar, Mako, or other replaced fallback components at the same time.

The shell package must not depend on `/usr/share/omarchy`, an Arch package layout, or an ambient `OMARCHY_PATH`. Packaged resources are addressed through a build-time or launcher-provided immutable path. Writable state follows XDG state and configuration directories.

## Shell structure

The Omarchy plugin host and reusable QML components are retained. First-party plugins outside the approved scope are excluded from the package or disabled by generated configuration; they are not merely hidden behind inaccessible menu entries.

The application launcher reads freedesktop desktop entries for applications already present in the Nix profile. Install actions, lazy-install behavior, web-app generation, and Omarchy catalog providers are removed.

The approved components use standard integrations where possible:

- system tray through Quickshell's StatusNotifier implementation;
- audio through PipeWire;
- battery and power information through UPower and power-profiles-daemon when available;
- network through NetworkManager;
- Bluetooth through BlueZ;
- notifications through the shell's notification server;
- lock through Wayland session-lock and PAM;
- layer surfaces through standard wlr-layer-shell support.

## Compositor boundary

UI components consume a compositor facade rather than importing compositor-specific objects or running compositor commands directly. The facade exposes only the state and actions needed by the approved UI:

- outputs and focused output;
- workspaces, occupancy, and focused workspace;
- active window metadata;
- keyboard layout state and layout switching;
- focus workspace and focus window;
- output enablement, mode, position, and scale operations needed by the monitor panel;
- output power control needed by idle behavior;
- session state needed by lock and idle integration.

The first implementation, `HyprlandBackend`, may use Quickshell's Hyprland module and reviewed `hyprctl` calls internally. No UI component calls `hyprctl` or imports `Quickshell.Hyprland` directly after migration to the facade.

The later `NiriBackend` will implement the same facade using the Niri IPC socket and event stream. Differences in workspace semantics remain inside the backend. UI models use stable shell-level identifiers and do not assume Hyprland's static workspace behavior.

The incomplete Rust compositor daemon is not required for the first version. It should not become a second source of truth alongside QML and a Python fallback. The first implementation chooses one runtime path; a daemon can be introduced later only for a demonstrated need such as robust streaming IPC or shared state that Quickshell cannot own cleanly.

## Runtime actions without Omarchy CLI

Features that currently invoke `omarchy-*` helpers are handled in one of three ways:

1. use an existing typed Quickshell service directly;
2. invoke a standard system command supplied declaratively by NixOS;
3. provide a narrowly scoped internal helper inside the shell package.

Internal helpers have feature-specific names and contracts. They do not dispatch arbitrary commands, install packages, edit Nix files, or reproduce the broad Omarchy CLI router.

Power actions use logind/systemd interfaces. Audio, network, and Bluetooth prefer their service APIs or standard tools. Monitor and workspace actions go exclusively through the compositor facade. Persistent monitor layout belongs to the declarative Hyprland configuration; the panel's runtime changes apply only to the live session unless an explicit future design adds declarative persistence.

## Hyprland session

Hyprland becomes the default graphical session for the first milestone. The existing Niri modules remain in the repository but are not active in the Hyprland host profile. The module boundary must make the compositor choice explicit so a future host or profile can select Niri without editing unrelated shell, application, or service modules.

The current fallback tools remain installed or readily buildable during development. Once the shell provides a tested replacement:

- its notification service replaces Mako;
- its launcher replaces Fuzzel for normal use;
- its bar replaces Waybar;
- its lock and idle implementation replaces swaylock and swayidle.

Fallback services must not compete for protocols or layer surfaces while Itterum Shell is active. A documented rescue command may start the fallback environment manually if the shell cannot launch, but it is not part of the normal session.

## Configuration and applications

Shell defaults are generated or installed declaratively. The initial bar keeps the system tray as the final item in the right section. User changes that should survive rebuilds are represented as Home Manager configuration rather than edits inside the immutable package.

The application launcher reflects the explicit graphical package list already owned by the workstation configuration. It may also display desktop entries created by user-installed Home Manager packages. It does not display remote catalogs, suggested applications, install buttons, or Omarchy web apps.

The exact initial application allowlist remains a separate configuration decision. Removing Omarchy defaults does not remove runtime dependencies required by selected shell capabilities.

## Failure handling

The shell runs under systemd user supervision and restarts after an unexpected exit. Restart behavior must be bounded to avoid a hot crash loop and must leave Hyprland usable through compositor key bindings.

Individual service failures degrade only their component. For example, missing Bluetooth hardware hides or disables Bluetooth controls without stopping the bar; unavailable power-profile support does the same for its selector. Invalid optional plugin configuration must not prevent the core bar, launcher, or session actions from loading.

The compositor backend reports unavailable state explicitly. UI components must not fabricate successful actions when Hyprland IPC fails. Logs are available through the user journal and identify the component and command or service that failed.

## Validation

Static and build validation includes:

- the shell flake exports an installable package for `x86_64-linux`;
- the workstation flake uses the same Nixpkgs revision for the shell where practical;
- Nix evaluation proves that Hyprland and the shell service are enabled together;
- negative checks prove that application installers, web-app catalogs, Arch update actions, and automatic Niri activation are absent;
- QML lint or shell-provided tests cover the compositor facade and enabled plugin configuration;
- focused tests cover the Hyprland workspace and action mapping;
- a no-link build succeeds for the complete NixOS system.

Runtime acceptance in a graphical VM or test machine includes:

- login reaches a usable Hyprland session;
- one bar appears on each intended output without duplicate fallback bars;
- workspaces update and can be focused;
- active-window and keyboard-layout state update;
- tray remains the rightmost right-section item;
- launcher lists installed applications and contains no install or web-app actions;
- notifications and OSD appear correctly;
- audio, network, Bluetooth, power, and monitor panels degrade safely when a capability is absent;
- lock authenticates and idle transitions work;
- killing the shell causes a controlled restart;
- the user journal contains no repeating crash loop or unresolved protocol ownership conflict.

Visual acceptance compares the running bar, panels, launcher, notifications, OSD, and lock screen with the Omarchy reference at representative resolutions and scaling factors.

## Delivery sequence

1. Clean and package the shell source without changing its appearance.
2. Add the Home Manager integration and a supervised Hyprland session startup.
3. Remove unapproved plugins, installers, catalogs, and Omarchy distribution assumptions.
4. Introduce the compositor facade and move all direct Hyprland access into `HyprlandBackend`.
5. Activate and verify the core bar, launcher, tray, clock, workspaces, and active-window state.
6. Activate notifications and OSD.
7. Activate audio, network, Bluetooth, power, and monitor panels.
8. Activate lock and idle behavior.
9. Disable superseded fallback services and complete graphical acceptance testing.
10. Design and implement `NiriBackend` as a later milestone.

## Completion criteria

The first milestone is complete when the NixOS configuration builds declaratively, login starts Hyprland and one supervised Itterum Shell instance, every approved MVP component passes runtime acceptance, no excluded Omarchy installation or web-app surface remains reachable, and the desktop remains recoverable if the shell process fails.

Niri support is explicitly deferred. The first milestone must leave a documented compositor facade and no direct Hyprland dependencies in ordinary UI components, making the later backend an additive integration rather than another shell rewrite.
