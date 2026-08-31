# Matugen Desktop Theming Design

## Goal

Use the wallpaper selected by Wayle as the single source for a dark Material You palette and apply that palette across the `itterum` desktop on both NixOS hosts.

Wayle owns wallpaper state and invokes Matugen whenever the active wallpaper or extraction settings change. Matugen then updates themes for Wayle, Fuzzel, Ghostty, Niri, gtklock, GTK 3, GTK 4, Qt 5, Qt 6, Helix, and Zed.

## Scope

The first version covers the shared Home Manager desktop profile and the system gtklock configuration for the `itterum` user. It keeps the existing cursor and WhiteSur icon theme. It does not attempt to recolor browser content, third-party applications with private theme formats, application icons, or other users' sessions.

The generated scheme is:

- dark mode;
- `tonal-spot` Material You scheme;
- contrast `0.0`;
- source color index `0`.

These values are declared in the Wayle configuration so the Wayle invocation of Matugen and the Wayle runtime palette stay aligned.

## Chosen Architecture

Wayle is the only wallpaper controller and the only runtime trigger for color extraction. Its `styling.theme-provider` is set to `matugen`. Wayle 0.7 invokes the Matugen executable when a configured wallpaper becomes active and stores the JSON palette used by its own styling layer.

Matugen also reads `$XDG_CONFIG_HOME/matugen/config.toml` during that invocation. The same process renders the application-specific templates and runs safe reload hooks. This avoids a wrapper command, a second extraction pass, and a filesystem-watching service.

The repository owns the Matugen configuration and input templates through Home Manager. Generated theme files are deliberately not Home Manager targets because they must remain writable at runtime.

No new flake input is required. The existing nixpkgs pin provides Matugen, and the package is added to the user's package set explicitly even though the Wayle Home Manager module can also auto-install the selected provider.

## Repository Structure

Add a focused Home Manager module and local templates:

```text
modules/home/desktop/
  matugen.nix
  matugen/
    templates/
      fuzzel.ini
      ghostty.conf
      gtk.css
      gtklock.css
      helix.toml
      niri.kdl
      qtct.conf
      zed.json
```

GTK 3 and GTK 4 share the single `gtk.css` input template, with separate output entries. Qt 5 and Qt 6 likewise share the single `qtct.conf` input template. This keeps equivalent formats in sync without duplicating template content.

`modules/home/desktop/default.nix` imports `matugen.nix`. Existing application modules retain ownership of non-color settings and only change enough to consume the generated theme.

## Runtime Data Flow

1. Home Manager activates the desktop configuration and places the Matugen configuration and templates under `$XDG_CONFIG_HOME/matugen`.
2. An activation step creates required mutable output directories and performs an initial generation from the repository-managed wallpaper only when one or more required generated files are absent.
3. Wayle starts with the Matugen theme provider and the configured wallpaper.
4. Wayle invokes `matugen image` with the declared scheme, contrast, source index, and dark mode.
5. Matugen writes its JSON palette for Wayle and renders every configured application template.
6. Matugen post-hooks notify applications that support live reload. Applications without a reliable reload mechanism use the new theme on their next start.
7. Later wallpaper changes made through Wayle's settings, CLI, or cycling follow the same path.

The initial generation must use the same scheme arguments as Wayle. It must not run unconditionally on every Home Manager activation because that would replace a palette derived from a user-selected wallpaper with the repository default.

## File Ownership and Bootstrap

Home Manager owns:

- `$XDG_CONFIG_HOME/matugen/config.toml`;
- all Matugen input templates;
- static application configuration that selects or imports a Matugen theme;
- the activation logic that creates mutable directories and seeds missing outputs.

Matugen owns only its generated outputs. They live under their applications' normal configuration directories, for example `fuzzel/matugen.ini`, `ghostty/themes/Matugen`, `niri/colors.kdl`, and `zed/themes/matugen.json`.

The activation step checks the complete required output set. If any output is absent, it runs one full generation so all files are mutually consistent. Existing generated files are otherwise preserved.

Every output directory is created before generation. Hook commands must end successfully when their target application is not running, so a closed application cannot make Wayle report color extraction failure.

## Application Integration

### Wayle

Set `styling.theme-provider = "matugen"`, `styling.matugen-scheme = "tonal-spot"`, `styling.matugen-contrast = 0.0`, `styling.matugen-source-color = 0`, and `styling.matugen-light = false`.

Retain the current static `styling.palette` as Wayle's fallback if its cached Matugen output is missing or invalid.

Configure the repository wallpaper for both known connectors, `eDP-1` and `HDMI-A-1`. Both use the same image. This guarantees that either connected laptop output can drive extraction. The desktop bootstrap configuration currently declares the same outputs; a future real desktop monitor layout may replace these connector entries without changing the theming architecture.

### Fuzzel

Remove the hard-coded color table from the Home Manager Fuzzel settings and include a generated `matugen.ini`. Fuzzel reads the generated colors each time it opens, so no reload hook is required.

### Ghostty

Select the generated theme named `Matugen`. The template defines the terminal foreground, background, cursor, selection, and ANSI palette. A post-hook sends Ghostty `SIGUSR2`, ignoring the no-process result.

### Niri

Keep the typed `programs.niri.settings` configuration as the source of the base compositor configuration. Retarget the niri-flake-generated and validated file to `niri/base.kdl`.

Home Manager supplies a small `niri/config.kdl` wrapper that includes `base.kdl` first and an optional mutable `colors.kdl` second. The generated color include overrides only focus-ring colors. Niri watches included files, so updating `colors.kdl` triggers its normal config reload without an explicit post-hook.

Remove the three hard-coded focus-ring color declarations from `modules/home/desktop/niri/appearance.nix`. Geometry and shadow settings stay declarative and unchanged.

### GTK 3 and GTK 4

Keep `adw-gtk3-dark` and the existing dark-mode preferences. Home Manager's GTK 3 and GTK 4 CSS entry points import generated color CSS files. The templates define Material color variables and the supported widget overrides without replacing the base GTK theme.

GTK applications are not assumed to reload CSS uniformly. Existing applications may need a restart; newly launched applications must use the generated palette.

### Qt 5 and Qt 6

Generate qtct-compatible palette files for both toolkit versions. Set `custom_palette = true` and point each existing qtct configuration to its generated palette while preserving the WhiteSur icon theme and current platform theme.

Qt applications are not assumed to reload an external palette while running. Newly launched applications must use it.

### gtklock

Keep the NixOS-managed gtklock program and PAM configuration. Its static stylesheet imports a generated user-readable CSS file from `/home/itterum/.config/gtklock/matugen.css`. The existing wallpaper, layout, and base theme remain unchanged; the generated file provides text, entry, and accent colors.

The next gtklock process uses the new CSS. No attempt is made to restyle a lock screen that is already active.

### Helix

Generate `$XDG_CONFIG_HOME/helix/themes/matugen.toml` and select `theme = "matugen"`. The template supplies editor UI and syntax colors while preserving transparency for the main background.

Running Helix instances are not signaled automatically. New instances use the new file; a running instance can reload or reselect the theme manually.

### Zed

Generate a valid Zed theme family JSON under `$XDG_CONFIG_HOME/zed/themes` and select its dark theme explicitly in `programs.zed-editor.userSettings`. Keep the light-mode entry valid as a fallback, but do not generate or automatically select a light palette in this version.

Do not overwrite Zed's Home Manager-managed `settings.json`. Zed may notice theme-file changes, but restart behavior is the supported fallback if an open instance does not refresh.

## Failure Handling

- Wayle keeps its declared static palette when Matugen JSON cannot be read.
- Generated application files are not deleted before regeneration, so an extraction failure before rendering leaves the previous theme available. Matugen renders templates sequentially, so a later template failure can leave a temporarily mixed set; the next successful invocation converges every output to one palette.
- All reload hooks tolerate a missing process.
- Required parent directories are created during activation.
- The Niri generated include is optional in the wrapper, allowing the compositor to start with the declarative base configuration before bootstrap generation completes.
- A template generation or syntax failure is a test failure and must not be hidden with broad `continue-on-error` behavior.

## Testing

Extend `tests/configuration.sh` to assert for both hosts that:

- Matugen is present in `home.packages`;
- Wayle uses the Matugen provider and the agreed dark `tonal-spot` settings;
- both known Wayle wallpaper connector entries reference the managed wallpaper;
- the Matugen configuration and every input template are Home Manager-managed files;
- Fuzzel, Ghostty, GTK, Qt, gtklock, Helix, Zed, and Niri point to their generated theme files;
- Niri's base and wrapper arrangement preserves the existing generated configuration and adds the optional color include;
- hard-coded dynamic color values no longer remain in the affected application settings;
- the existing static palette remains available to Wayle as fallback.

Add a generation smoke test that redirects Matugen output under a temporary prefix or temporary home, renders all templates from the managed wallpaper, and verifies:

- every expected output exists and is non-empty;
- generated JSON and TOML files parse;
- the generated Niri include and the assembled Niri wrapper validate with the configured Niri package;
- generated theme files contain no unresolved Matugen expressions.

Run the existing repository checks after the focused tests:

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
nix build --no-link 'path:.#nixosConfigurations.laptop.config.system.build.toplevel'
nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'
```

## Documentation

Update the README's declarative desktop section to describe Wayle as the wallpaper and palette driver, list the dynamically themed components, identify Matugen's generated files as intentionally mutable runtime state, and document that GTK, Qt, Helix, and Zed may require application restart or manual reload.

## Non-Goals

- automatic light/dark switching;
- separate palettes per monitor;
- recoloring icons or cursors;
- browser-content themes;
- themes for applications not already configured in this repository;
- replacing Wayle with a custom wallpaper wrapper or watcher;
- making generated runtime theme files part of the Nix store.
