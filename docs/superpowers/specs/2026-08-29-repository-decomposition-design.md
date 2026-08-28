# Repository decomposition design

Date: 2026-08-29

## Goal

Finish the partially started repository reorganization so that NixOS and Home
Manager configuration have explicit ownership boundaries, large configuration
files are split by responsibility, and every active component is easy to find.
Replace the checked-in Niri KDL source with validated, Nix-native settings while
keeping Wayle as the active desktop shell and keeping experimental Quickshell
sources disconnected from both hosts.

## Constraints

- Preserve all current staged and unstaged user changes that remain relevant to
  the target configuration.
- Do not activate a generation, run `nixos-rebuild switch`, restart a graphical
  service, or modify files in the live home directory.
- Both `laptop` and `desktop` must continue to use the same workstation and Home
  Manager profiles, with host-specific hardware and power configuration layered
  on top.
- Keep Niri's active output layout, input behavior, appearance, animations,
  window rules, and bindings unless a binding depends on removed software.
- Wayle remains active and replaces Mako as the notification shell.
- Files below `experiments/` are examples under development and must not be
  imported into either host.
- The wallpaper source of truth is
  `assets/wallpapers/nix-wallpaper.png`.

## Composition boundaries

The repository has two explicit composition layers:

```text
flake.nix
  -> hosts/<host>/default.nix
     -> profiles/nixos/workstation.nix
        -> modules/nixos/**

flake.nix
  -> home/itterum/default.nix
     -> profiles/home/workstation.nix
        -> modules/home/**
```

Host modules own only hardware imports and settings that differ by machine.
NixOS profiles import system modules; Home Manager profiles import user modules.
Leaf modules do not import profiles and do not cross the NixOS/Home Manager
boundary. Aggregating `default.nix` files contain imports and only the small
amount of configuration that genuinely belongs to the aggregate.

`home/itterum/default.nix` owns the `itterum` username, home directory, state
version, and the single Home Manager profile import. System user creation and
the login shell remain in the NixOS base module.

## Target NixOS modules

```text
modules/nixos/
├── system/base.nix
├── desktop/
│   ├── niri.nix
│   ├── audio.nix
│   ├── portals.nix
│   └── session.nix
├── hardware/
│   ├── bluetooth.nix
│   └── nvidia.nix
├── network/casting.nix
├── programs/
│   ├── browsers.nix
│   └── chatgpt.nix
└── virtualisation/containers.nix
```

`profiles/nixos/workstation.nix` imports every shared system module. The desktop
host additionally imports NVIDIA support. The laptop additionally enables TLP
and disables power-profiles-daemon. The existing small base module stays intact:
splitting boot, locale, user, and package declarations further would make the
configuration harder to navigate without reducing a large file.

The ChatGPT module stays on the NixOS side because it writes
`environment.systemPackages`. System-wide Zsh enablement and the user's login
shell are folded into `system/base.nix`; interactive Zsh, Starship, and direnv
configuration remain in Home Manager.

## Target Home Manager modules

```text
modules/home/
├── desktop/
│   ├── default.nix
│   ├── palette.nix
│   ├── fuzzel.nix
│   ├── idle.nix
│   ├── theme.nix
│   ├── wayle.nix
│   └── niri/
│       ├── default.nix
│       ├── input.nix
│       ├── outputs.nix
│       ├── appearance.nix
│       ├── animations.nix
│       ├── rules.nix
│       └── binds/
│           ├── default.nix
│           ├── applications.nix
│           ├── media.nix
│           ├── workspaces.nix
│           ├── windows.nix
│           ├── monitors.nix
│           └── session.nix
├── shell/default.nix
└── programs/
    ├── ghostty.nix
    ├── zed.nix
    └── helix/
        ├── default.nix
        ├── editor.nix
        └── languages/
            ├── default.nix
            ├── web.nix
            ├── rust.nix
            ├── python.nix
            └── misc.nix
```

`profiles/home/workstation.nix` imports the desktop aggregate, shell module,
Ghostty, Helix, and Zed. Desktop helper packages stay next to the component that
uses them; general command-line utilities live in the shell module.

`palette.nix` is a plain Nix value containing the shared Catppuccin Mocha color
set. Niri, Fuzzel, Wayle, and GTK/Qt theming import it directly. This avoids
duplicated color literals without introducing a repository-specific option
namespace solely for static data.

The current Helix configuration is split because it is already roughly 450
lines. `default.nix` enables Helix and composes the submodules, `editor.nix`
owns editor behavior and keymaps, and language files own related language
servers, formatters, and language declarations. Smaller application modules are
not split merely for symmetry.

## Niri as Nix-native configuration

Add `github:sodiboo/niri-flake` as a locked flake input and use its Home Manager
configuration module. Continue installing and launching the Niri package from
the pinned nixpkgs input; configure niri-flake validation against the same
system package so the settings schema and generated configuration are checked
during evaluation or build.

No KDL source file remains in the repository. Every Niri leaf module contributes
to `programs.niri.settings`, and the Nix module system merges those settings.
The generated KDL is a build output exposed through
`programs.niri.finalConfig`, not a maintained source file.

The Niri modules have these responsibilities:

- `default.nix`: import the niri-flake config module and all local Niri modules;
  connect validation to the system Niri package; define small global settings.
- `input.nix`: keyboard, pointer, touchpad, cursor, and gesture settings.
- `outputs.nix`: the static HDMI-A-1 and eDP-1 modes, scales, and positions.
- `appearance.nix`: layout, focus ring, borders, shadows, overview, screenshot
  path, environment, and client-side-decoration policy.
- `animations.nix`: all animation curves, durations, and springs.
- `rules.nix`: window and layer rules, including default geometry behavior.
- `binds/*`: application, media, workspace, window, monitor, layout, screenshot,
  and session actions grouped by purpose.

Bindings that invoke Fuzzel, swaylock, Ghostty, WirePlumber, playerctl, or
brightnessctl remain. Bindings that invoke `makoctl` are removed because Wayle
owns notifications and no compatible Wayle dismissal CLI is part of the pinned
configuration. Other existing behavior is preserved.

The pinned niri-flake settings schema does not expose Niri's `recent-windows`
section. Niri therefore uses its built-in recent-window defaults. The current
custom highlight colors and output-scoped Alt+Tab override are intentionally
not migrated; using the defaults keeps the rest of the configuration typed and
avoids replacing `programs.niri.settings` with an untyped KDL document.

## Wayle, notifications, and wallpaper

`modules/home/desktop/wayle.nix` enables `services.wayle` with its existing bar,
modules, scale, and Catppuccin styling. Wayle is the only notification shell;
Home Manager does not enable Mako.

Home Manager installs the repository wallpaper as
`~/Pictures/Wallpapers/nix-wallpaper.png`. The Wayle setting derives the target
path from `config.home.homeDirectory`, rather than embedding
`/home/itterum`. Its wallpaper engine remains enabled with cycling disabled and
uses that installed file on eDP-1.

## Experiments and obsolete paths

Move the current experimental Quickshell tree to:

```text
experiments/itterum-shell/
├── shell.qml
└── services/
    ├── Niri.qml
    └── qmldir
```

No production profile or module references this directory. Obsolete Quickshell
module glue, the old top-level `itterum-shell/`, `experimentals/`, old
`modules/{desktop,hardware,network,programs,profiles,system,virtualisation}`
paths, the Home Manager monoliths, and the checked-in Niri KDL are removed only
after their replacements are connected.

## Documentation and migration safety

Update README paths and desktop descriptions to match the final layout and
Wayle ownership. Older dated design and implementation documents remain as
historical records; this specification is authoritative for the decomposition.

The migration works with the current mixed index and working-tree state. It may
move or rewrite files that are already modified, but it must not restore deleted
DMS assets, discard current Helix/Zed settings, or lose the experimental shell
sources. The final diff must be inspected against both `HEAD` and the preexisting
working state.

## Verification

Update `tests/configuration.sh` to evaluate both hosts through `path:` and assert:

- hostnames, power policy, NVIDIA isolation, greetd, and Niri remain correct;
- both hosts use the new NixOS and Home Manager profiles;
- Fuzzel, swayidle, swaylock, and Wayle are enabled;
- Mako and DMS are disabled;
- the icon and cursor themes remain Papirus-Dark and macOS;
- the wallpaper file source resolves to the repository asset;
- `programs.niri.finalConfig` contains representative output, application,
  media, workspace, window, monitor, and session settings;
- no maintained Niri KDL source or import from `experiments/` remains.

Run the following verification without activating the result:

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
nix build --no-link 'path:.#nixosConfigurations.laptop.config.system.build.toplevel'
nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'
git diff --check
```

Finally, inspect the repository tree, all import paths, the scoped configuration
diff, and the remaining Git status. Both builds must succeed; warnings from
pinned upstream inputs are reported separately from failures introduced by the
migration.
