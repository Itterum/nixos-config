# Matugen Desktop Theming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Wayle drive one dark Matugen palette and apply it to the complete configured desktop: Wayle, Fuzzel, Ghostty, Niri, gtklock, GTK, Qt, Helix, and Zed.

**Architecture:** Wayle remains the only wallpaper controller and selects its built-in Matugen provider. Matugen reads a Home Manager-managed configuration during Wayle's extraction call, renders writable application theme files, and lets each consumer import or select those files. Home Manager seeds missing outputs once from the managed wallpaper and otherwise preserves the last runtime-generated palette.

**Tech Stack:** NixOS 26.05, Home Manager 26.05, Wayle 0.7, Matugen 4, Bash regression tests, KDL, TOML, INI, GTK CSS, and Zed JSON themes.

**Spec:** `docs/superpowers/specs/2026-08-31-matugen-desktop-theming-design.md`

## Global Constraints

- Use dark mode, Matugen scheme `tonal-spot`, contrast `0.0`, and source color index `0`.
- Wayle is the only runtime wallpaper controller and extraction trigger; do not add a wrapper or watcher service.
- Do not add a flake input; use `pkgs.matugen` from the pinned nixpkgs.
- Keep the current WhiteSur icon theme and macOS cursor theme.
- Generated theme outputs must remain writable runtime files and must not become Home Manager file targets.
- Keep Wayle's current static palette as its fallback.
- Keep the typed `programs.niri.settings` configuration as the base Niri configuration.
- Do not hide template or syntax failures with broad continue-on-error behavior.
- Preserve user-selected generated themes during later Home Manager activations; seed only when at least one required output is missing.

---

## File Structure

**Create:**

- `modules/home/desktop/matugen.nix` — package, Matugen TOML, template links, mutable output directories, and bootstrap generation.
- `modules/home/desktop/matugen/templates/fuzzel.ini` — generated Fuzzel color section.
- `modules/home/desktop/matugen/templates/ghostty.conf` — generated Ghostty terminal palette.
- `modules/home/desktop/matugen/templates/gtk.css` — shared GTK 3/4 Material color definitions.
- `modules/home/desktop/matugen/templates/gtklock.css` — gtklock-specific color variables.
- `modules/home/desktop/matugen/templates/helix.toml` — generated transparent Helix theme.
- `modules/home/desktop/matugen/templates/niri.kdl` — generated Niri focus-ring colors.
- `modules/home/desktop/matugen/templates/qtct.conf` — shared Qt 5/6 qtct palette.
- `modules/home/desktop/matugen/templates/zed.json` — generated Zed dark/light theme family.
- `tests/matugen-generation.sh` — isolated template-generation and syntax smoke test.

**Modify:**

- `modules/home/desktop/default.nix` — import the Matugen module.
- `modules/home/desktop/wayle.nix` — select Matugen and configure the wallpaper on both known connectors.
- `modules/home/desktop/fuzzel.nix` — replace static colors with the generated include.
- `modules/home/programs/ghostty.nix` — select the generated theme.
- `modules/home/desktop/niri/default.nix` — split Niri into validated base plus wrapper and dynamic include.
- `modules/home/desktop/niri/appearance.nix` — remove static focus-ring colors.
- `modules/home/desktop/theme.nix` — import GTK colors and select Qt palettes.
- `modules/nixos/desktop/lock.nix` — import and consume generated gtklock colors.
- `modules/home/programs/helix/default.nix` — remove the old static transparent theme.
- `modules/home/programs/helix/editor.nix` — select `matugen`.
- `modules/home/programs/zed.nix` — select the Matugen theme family.
- `tests/configuration.sh` — evaluation assertions and smoke-test entry point.
- `README.md` — document runtime generation and reload behavior.

---

### Task 1: Install Matugen and Make Wayle the Palette Driver

**Files:**

- Create: `modules/home/desktop/matugen.nix`
- Modify: `modules/home/desktop/default.nix`
- Modify: `modules/home/desktop/wayle.nix`
- Modify: `tests/configuration.sh`

**Interfaces:**

- Consumes: `pkgs.matugen`, the existing `services.wayle` Home Manager module, `assets/wallpapers/nix-wallpaper.png`, and `modules/home/desktop/palette.nix`.
- Produces: `$XDG_CONFIG_HOME/matugen/config.toml`, Matugen on the user PATH, and Wayle settings that invoke Matugen for the managed wallpaper.

- [ ] **Step 1: Add failing evaluation assertions**

Inside the existing `for host in laptop desktop; do` loop in `tests/configuration.sh`, after the Wayle enable assertion, add:

```bash
  assert_contains \
    'matugen-' \
    "$(flake_json "$host" "$home_prefix.home.packages")" \
    "$host Matugen package"
  assert_eq \
    '"matugen"' \
    "$(flake_json "$host" "$home_prefix.services.wayle.settings.styling.theme-provider")" \
    "$host Wayle Matugen provider"
  assert_eq \
    '"tonal-spot"' \
    "$(flake_json "$host" "$home_prefix.services.wayle.settings.styling.matugen-scheme")" \
    "$host Wayle Matugen scheme"
  assert_eq \
    "0" \
    "$(flake_json "$host" "$home_prefix.services.wayle.settings.styling.matugen-contrast")" \
    "$host Wayle Matugen contrast"
  assert_eq \
    "0" \
    "$(flake_json "$host" "$home_prefix.services.wayle.settings.styling.matugen-source-color")" \
    "$host Wayle Matugen source color"
  assert_eq \
    "false" \
    "$(flake_json "$host" "$home_prefix.services.wayle.settings.styling.matugen-light")" \
    "$host Wayle Matugen dark mode"
```

After `home_files` is evaluated, add assertions for the managed Matugen config and both wallpaper monitor entries:

```bash
assert_contains '.config/matugen/config.toml' "$home_files" "managed Matugen config"

wayle_monitors=$(flake_json laptop \
  "home-manager.users.itterum.services.wayle.settings.wallpaper.monitors")
assert_contains '"name":"eDP-1"' "$wayle_monitors" "Wayle eDP wallpaper"
assert_contains '"name":"HDMI-A-1"' "$wayle_monitors" "Wayle HDMI wallpaper"
assert_occurrences \
  "2" \
  'nix-wallpaper.png' \
  "$wayle_monitors" \
  "Wayle managed wallpaper count"
```

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```bash
bash tests/configuration.sh
```

Expected: FAIL because Matugen is not in `home.packages` and Wayle has no `theme-provider = "matugen"` setting.

- [ ] **Step 3: Add the minimal Matugen module**

Create `modules/home/desktop/matugen.nix` with an initially empty template table:

```nix
{
  config,
  pkgs,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };
  matugenConfig = tomlFormat.generate "matugen-config.toml" {
    config.version_check = false;
    templates = { };
  };
in
{
  home.packages = [ pkgs.matugen ];

  xdg.configFile."matugen/config.toml".source = matugenConfig;
}
```

Import it in `modules/home/desktop/default.nix` before the application consumers:

```nix
  imports = [
    ./matugen.nix
    ./fuzzel.nix
    ./idle.nix
    ./theme.nix
    ./wayle.nix
    ./niri
  ];
```

- [ ] **Step 4: Configure Wayle's provider and both known outputs**

In `modules/home/desktop/wayle.nix`, keep the static `palette` block and change `styling` to include:

```nix
      styling = {
        scale = 1;
        theme-provider = "matugen";
        matugen-scheme = "tonal-spot";
        matugen-contrast = 0.0;
        matugen-source-color = 0;
        matugen-light = false;
      };
```

Add these five Matugen fields alongside the existing `scale` and `palette` assignments; do not replace or duplicate the current palette body.

Replace the single wallpaper monitor entry with:

```nix
        monitors = map (name: {
          inherit name;
          wallpaper = wallpaperPath;
          fit-mode = "fill";
        }) [
          "eDP-1"
          "HDMI-A-1"
        ];
```

- [ ] **Step 5: Run evaluation checks**

Run:

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
```

Expected: both commands PASS; existing static Wayle palette assertions remain green.

- [ ] **Step 6: Commit**

```bash
git add modules/home/desktop/matugen.nix \
  modules/home/desktop/default.nix \
  modules/home/desktop/wayle.nix \
  tests/configuration.sh
git commit -m "feat: drive Wayle colors with matugen"
```

---

### Task 2: Theme Fuzzel, Ghostty, and Niri

**Files:**

- Create: `modules/home/desktop/matugen/templates/fuzzel.ini`
- Create: `modules/home/desktop/matugen/templates/ghostty.conf`
- Create: `modules/home/desktop/matugen/templates/niri.kdl`
- Modify: `modules/home/desktop/matugen.nix`
- Modify: `modules/home/desktop/fuzzel.nix`
- Modify: `modules/home/programs/ghostty.nix`
- Modify: `modules/home/desktop/niri/default.nix`
- Modify: `modules/home/desktop/niri/appearance.nix`
- Modify: `tests/configuration.sh`

**Interfaces:**

- Consumes: the Matugen config from Task 1 and the typed `programs.niri.settings` tree.
- Produces: writable `fuzzel/matugen.ini`, `ghostty/themes/Matugen`, and `niri/colors.kdl`; a validated Niri `base.kdl`; and a Home Manager-managed `niri/config.kdl` wrapper.

- [ ] **Step 1: Add failing shell-consumer assertions**

Add these assertions inside the host loop:

```bash
  assert_eq \
    '"/home/itterum/.config/fuzzel/matugen.ini"' \
    "$(flake_json "$host" "$home_prefix.programs.fuzzel.settings.main.include")" \
    "$host Fuzzel Matugen include"
  assert_eq \
    '"Matugen"' \
    "$(flake_json "$host" "$home_prefix.programs.ghostty.settings.theme")" \
    "$host Ghostty Matugen theme"
```

After `home_files` is evaluated, add:

```bash
for template in fuzzel.ini ghostty.conf niri.kdl; do
  assert_contains \
    ".config/matugen/templates/${template}" \
    "$home_files" \
    "managed Matugen ${template} template"
done
assert_contains '.config/niri/base.kdl' "$home_files" "managed Niri base"
assert_contains '.config/niri/config.kdl' "$home_files" "managed Niri wrapper"
```

Replace the old Niri static-color expectations with wrapper assertions:

```bash
niri_wrapper=$(flake_value laptop \
  'home-manager.users.itterum.xdg.configFile."niri/config.kdl".text')
assert_contains 'include "base.kdl"' "$niri_wrapper" "Niri base include"
assert_contains \
  'include optional=true "colors.kdl"' \
  "$niri_wrapper" \
  "Niri optional Matugen include"
assert_not_contains '#3584e4' "$niri_config" "Niri no static accent"
```

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```bash
bash tests/configuration.sh
```

Expected: FAIL on the missing Fuzzel include, Ghostty theme, Matugen templates, and Niri wrapper.

- [ ] **Step 3: Vendor the Fuzzel and Ghostty templates and create the reduced Niri template**

Use the official `matugen-themes` files pinned to commit `707c7b7d3550c9c21c0a8d72186748b1d205b88b`, add them with `apply_patch`, and verify their content before adapting paths:

```text
https://raw.githubusercontent.com/InioX/matugen-themes/707c7b7d3550c9c21c0a8d72186748b1d205b88b/templates/fuzzel.ini
sha256: 72cf53adc9154be54d73c1417aecee007dc95f9d55157df96157dba043f3774e

https://raw.githubusercontent.com/InioX/matugen-themes/707c7b7d3550c9c21c0a8d72186748b1d205b88b/templates/ghostty
sha256: 6f3853d7c6fab3c3b3336fbaf3b140135c0303500c9e81587a0780ab10323f1b
```

Store the second file as `ghostty.conf` without changing its content. Create `niri.kdl` with only the properties this repository wants to make dynamic:

```kdl
layout {
    focus-ring {
        active-color "{{colors.primary.default.hex}}"
        inactive-color "{{colors.outline.default.hex}}"
        urgent-color "{{colors.error.default.hex}}"
    }
}
```

- [ ] **Step 4: Extend the Matugen template table and bootstrap outputs**

Add `lib` to the module arguments, then refactor the `let` block in `matugen.nix` to define stable paths:

```nix
  configHome = config.xdg.configHome;
  templateDirectory = "${configHome}/matugen/templates";
  wallpaper = ../../../assets/wallpapers/nix-wallpaper.png;

  outputDirectories = [
    "${configHome}/fuzzel"
    "${configHome}/ghostty/themes"
    "${configHome}/niri"
  ];

  outputPaths = [
    "${configHome}/fuzzel/matugen.ini"
    "${configHome}/ghostty/themes/Matugen"
    "${configHome}/niri/colors.kdl"
  ];
```

Generate the config with exact template entries:

```nix
  matugenConfig = tomlFormat.generate "matugen-config.toml" {
    config.version_check = false;
    templates = {
      fuzzel = {
        input_path = "${templateDirectory}/fuzzel.ini";
        output_path = "${configHome}/fuzzel/matugen.ini";
      };
      ghostty = {
        input_path = "${templateDirectory}/ghostty.conf";
        output_path = "${configHome}/ghostty/themes/Matugen";
        post_hook = "pkill -SIGUSR2 ghostty || true";
      };
      niri = {
        input_path = "${templateDirectory}/niri.kdl";
        output_path = "${configHome}/niri/colors.kdl";
      };
    };
  };
```

Expose the three templates through `xdg.configFile`, then add bootstrap activation:

```nix
  xdg.configFile = {
    "matugen/config.toml".source = matugenConfig;
    "matugen/templates/fuzzel.ini".source = ./matugen/templates/fuzzel.ini;
    "matugen/templates/ghostty.conf".source = ./matugen/templates/ghostty.conf;
    "matugen/templates/niri.kdl".source = ./matugen/templates/niri.kdl;
  };

  home.activation.seedMatugen = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    needs_seed=0
    for output in ${builtins.concatStringsSep " " outputPaths}; do
      if [[ ! -s "$output" ]]; then
        needs_seed=1
      fi
    done

    if (( needs_seed )); then
      run ${pkgs.coreutils}/bin/mkdir -p ${builtins.concatStringsSep " " outputDirectories}
      run ${pkgs.matugen}/bin/matugen image ${wallpaper} \
        --config ${configHome}/matugen/config.toml \
        --mode dark \
        --type scheme-tonal-spot \
        --contrast 0 \
        --source-color-index 0 \
        --quiet
    fi
  '';
```

Do not add quotes around the Nix-expanded path lists: every current path is fixed and whitespace-free.

- [ ] **Step 5: Connect Fuzzel and Ghostty**

Change `fuzzel.nix` to accept `config`, remove the palette import and the entire static `colors` block, and set:

```nix
      main = {
        include = "${config.xdg.configHome}/fuzzel/matugen.ini";
      };
```

Merge `include` into the existing `main` block; preserve its font, terminal, layer, prompt, icon, size, and padding fields.

Change only Ghostty's theme selection:

```nix
      theme = "Matugen";
```

- [ ] **Step 6: Split Niri into base and wrapper files**

In `modules/home/desktop/niri/appearance.nix`, remove the `palette` let binding and remove `active.color`, `inactive.color`, and `urgent.color` from `layout.focus-ring`. Keep `width = 2`.

In `modules/home/desktop/niri/default.nix`, add `lib` to the arguments and replace the current single force assignment with:

```nix
  xdg.configFile = {
    niri-config = {
      target = lib.mkForce "niri/base.kdl";
      force = true;
    };
    "niri/config.kdl" = {
      text = ''
        include "base.kdl"
        include optional=true "colors.kdl"
      '';
      force = true;
    };
  };
```

Do not add a Niri post-hook: the configured Niri version watches included files.

- [ ] **Step 7: Run checks and inspect rendered Niri**

Run:

```bash
bash tests/configuration.sh
nix eval --raw \
  'path:.#nixosConfigurations.laptop.config.home-manager.users.itterum.programs.niri.finalConfig' \
  | rg '#3584e4|#77767b|#e01b24'
```

Expected: `configuration.sh` PASS; the `rg` command exits 1 because static focus-ring colors are gone.

- [ ] **Step 8: Commit**

```bash
git add modules/home/desktop/matugen.nix \
  modules/home/desktop/matugen/templates/fuzzel.ini \
  modules/home/desktop/matugen/templates/ghostty.conf \
  modules/home/desktop/matugen/templates/niri.kdl \
  modules/home/desktop/fuzzel.nix \
  modules/home/programs/ghostty.nix \
  modules/home/desktop/niri/default.nix \
  modules/home/desktop/niri/appearance.nix \
  tests/configuration.sh
git commit -m "feat: theme shell components with matugen"
```

---

### Task 3: Theme GTK, Qt, and gtklock

**Files:**

- Create: `modules/home/desktop/matugen/templates/gtk.css`
- Create: `modules/home/desktop/matugen/templates/gtklock.css`
- Create: `modules/home/desktop/matugen/templates/qtct.conf`
- Modify: `modules/home/desktop/matugen.nix`
- Modify: `modules/home/desktop/theme.nix`
- Modify: `modules/nixos/desktop/lock.nix`
- Modify: `tests/configuration.sh`

**Interfaces:**

- Consumes: `matugenConfig`, `outputDirectories`, and `outputPaths` from Task 2.
- Produces: writable GTK 3/4 CSS, gtklock CSS, and Qt 5/6 palette files selected by the existing toolkit configuration.

- [ ] **Step 1: Add failing toolkit assertions**

Inside the host loop, add:

```bash
  assert_contains \
    'matugen.css' \
    "$(flake_value "$host" "$home_prefix.gtk.gtk3.extraCss")" \
    "$host GTK 3 Matugen import"
  assert_contains \
    'matugen.css' \
    "$(flake_value "$host" "$home_prefix.gtk.gtk4.extraCss")" \
    "$host GTK 4 Matugen import"
  assert_eq \
    "true" \
    "$(flake_json "$host" "$home_prefix.qt.qt5ctSettings.Appearance.custom_palette")" \
    "$host Qt 5 custom palette"
  assert_eq \
    "true" \
    "$(flake_json "$host" "$home_prefix.qt.qt6ctSettings.Appearance.custom_palette")" \
    "$host Qt 6 custom palette"
  assert_contains \
    'qt5ct/colors/matugen.conf' \
    "$(flake_value "$host" "$home_prefix.qt.qt5ctSettings.Appearance.color_scheme_path")" \
    "$host Qt 5 Matugen palette"
  assert_contains \
    'qt6ct/colors/matugen.conf' \
    "$(flake_value "$host" "$home_prefix.qt.qt6ctSettings.Appearance.color_scheme_path")" \
    "$host Qt 6 Matugen palette"
```

Replace the gtklock hard-coded background assertion with:

```bash
  gtklock_style=$(flake_value "$host" programs.gtklock.style)
  assert_contains 'gtklock/matugen.css' "$gtklock_style" "$host gtklock Matugen import"
  assert_contains '@matugen_surface' "$gtklock_style" "$host gtklock generated surface"
  assert_contains '@matugen_primary' "$gtklock_style" "$host gtklock generated accent"
```

After `home_files` is evaluated, assert all three source templates:

```bash
for template in gtk.css gtklock.css qtct.conf; do
  assert_contains \
    ".config/matugen/templates/${template}" \
    "$home_files" \
    "managed Matugen ${template} template"
done
```

- [ ] **Step 2: Run the focused test and verify failure**

Run `bash tests/configuration.sh`.

Expected: FAIL because the GTK imports, Qt palette paths, gtklock variables, and templates do not exist.

- [ ] **Step 3: Vendor the shared GTK and Qt templates and add gtklock variables**

Add the official files from the same pinned commit with `apply_patch`:

```text
templates/gtk-colors.css -> modules/home/desktop/matugen/templates/gtk.css
sha256: 8f90781ed32707289f52bc4a43163a52901e3eae5ee74d9083a70fccf2dab463

templates/qtct-colors.conf -> modules/home/desktop/matugen/templates/qtct.conf
sha256: e4b8d11573d80f7ddc41521b992d054c300f370f875843758fa0aa9fa3765f46
```

Create `gtklock.css` exactly as:

```css
@define-color matugen_surface {{colors.surface.default.hex}};
@define-color matugen_on_surface {{colors.on_surface.default.hex}};
@define-color matugen_primary {{colors.primary.default.hex}};
```

- [ ] **Step 4: Add five toolkit outputs to Matugen**

Append these directories to `outputDirectories`:

```nix
    "${configHome}/gtk-3.0"
    "${configHome}/gtk-4.0"
    "${configHome}/gtklock"
    "${configHome}/qt5ct/colors"
    "${configHome}/qt6ct/colors"
```

Append these files to `outputPaths`:

```nix
    "${configHome}/gtk-3.0/matugen.css"
    "${configHome}/gtk-4.0/matugen.css"
    "${configHome}/gtklock/matugen.css"
    "${configHome}/qt5ct/colors/matugen.conf"
    "${configHome}/qt6ct/colors/matugen.conf"
```

Add exact Matugen entries:

```nix
      gtk3 = {
        input_path = "${templateDirectory}/gtk.css";
        output_path = "${configHome}/gtk-3.0/matugen.css";
      };
      gtk4 = {
        input_path = "${templateDirectory}/gtk.css";
        output_path = "${configHome}/gtk-4.0/matugen.css";
      };
      gtklock = {
        input_path = "${templateDirectory}/gtklock.css";
        output_path = "${configHome}/gtklock/matugen.css";
      };
      qt5ct = {
        input_path = "${templateDirectory}/qtct.conf";
        output_path = "${configHome}/qt5ct/colors/matugen.conf";
      };
      qt6ct = {
        input_path = "${templateDirectory}/qtct.conf";
        output_path = "${configHome}/qt6ct/colors/matugen.conf";
      };
```

Expose `gtk.css`, `gtklock.css`, and `qtct.conf` next to the existing managed input templates.

- [ ] **Step 5: Connect GTK and Qt consumers**

Change `theme.nix` to accept `config` and add:

```nix
    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
      extraCss = ''
        @import url("file://${config.xdg.configHome}/gtk-3.0/matugen.css");
      '';
    };
    gtk4 = {
      extraConfig.gtk-application-prefer-dark-theme = true;
      extraCss = ''
        @import url("file://${config.xdg.configHome}/gtk-4.0/matugen.css");
      '';
    };
```

Replace the existing one-line GTK 3/4 `extraConfig` assignments with these blocks. Extend both qtct Appearance blocks while preserving icons, dialogs, and `adwaita-dark`:

```nix
      custom_palette = true;
      color_scheme_path = "${config.xdg.configHome}/qt5ct/colors/matugen.conf";
```

Use `qt6ct` in the Qt 6 path.

- [ ] **Step 6: Connect gtklock**

Remove the palette import from `modules/nixos/desktop/lock.nix`. Put this import at the top of `programs.gtklock.style`:

```css
@import url("file:///home/itterum/.config/gtklock/matugen.css");
```

Change the dynamic declarations to:

```css
window {
  background-image: url("file://${wallpaper}");
  background-size: cover;
  background-position: center;
  color: @matugen_on_surface;
}

entry {
  background-color: alpha(@matugen_surface, 0.92);
  border: 2px solid @matugen_primary;
  border-radius: 10px;
  color: @matugen_on_surface;
}
```

- [ ] **Step 7: Run checks**

Run:

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add modules/home/desktop/matugen.nix \
  modules/home/desktop/matugen/templates/gtk.css \
  modules/home/desktop/matugen/templates/gtklock.css \
  modules/home/desktop/matugen/templates/qtct.conf \
  modules/home/desktop/theme.nix \
  modules/nixos/desktop/lock.nix \
  tests/configuration.sh
git commit -m "feat: theme desktop toolkits with matugen"
```

---

### Task 4: Theme Helix and Zed

**Files:**

- Create: `modules/home/desktop/matugen/templates/helix.toml`
- Create: `modules/home/desktop/matugen/templates/zed.json`
- Modify: `modules/home/desktop/matugen.nix`
- Modify: `modules/home/programs/helix/default.nix`
- Modify: `modules/home/programs/helix/editor.nix`
- Modify: `modules/home/programs/zed.nix`
- Modify: `tests/configuration.sh`

**Interfaces:**

- Consumes: the Matugen output and activation lists from Tasks 2 and 3.
- Produces: writable Helix and Zed themes selected by their existing Home Manager settings.

- [ ] **Step 1: Add failing editor assertions**

Inside the host loop, add:

```bash
  assert_eq \
    '"matugen"' \
    "$(flake_json "$host" "$home_prefix.programs.helix.settings.theme")" \
    "$host Helix Matugen theme"
  assert_eq \
    '"dark"' \
    "$(flake_json "$host" "$home_prefix.programs.zed-editor.userSettings.theme.mode")" \
    "$host Zed dark mode"
  assert_eq \
    '"Matugen Dark"' \
    "$(flake_json "$host" "$home_prefix.programs.zed-editor.userSettings.theme.dark")" \
    "$host Zed Matugen dark theme"
  assert_eq \
    '"Matugen Light"' \
    "$(flake_json "$host" "$home_prefix.programs.zed-editor.userSettings.theme.light")" \
    "$host Zed Matugen light fallback"
```

After `home_files`, add:

```bash
for template in helix.toml zed.json; do
  assert_contains \
    ".config/matugen/templates/${template}" \
    "$home_files" \
    "managed Matugen ${template} template"
done
```

- [ ] **Step 2: Run the focused test and verify failure**

Run `bash tests/configuration.sh`.

Expected: FAIL because Helix still selects `transparent_theme`, Zed still selects JetBrains themes, and the templates are absent.

- [ ] **Step 3: Vendor the editor templates**

Add the official templates from pinned commit `707c7b7d3550c9c21c0a8d72186748b1d205b88b` with `apply_patch`:

```text
templates/helix.toml -> modules/home/desktop/matugen/templates/helix.toml
sha256: b8f61d645005b6f2295ac3ab6638a7421505d861d91d153b3c64d650384a044e

templates/zed-colors.json -> modules/home/desktop/matugen/templates/zed.json
sha256: 8284a84b8aeb772470ea735fb5a1ae8a0f08b7d25d9685de0ff6458f0b89fc4d
```

Keep both Matugen Dark and Matugen Light in the Zed theme family so the settings object never refers to a missing light fallback.

- [ ] **Step 4: Add editor outputs to Matugen**

Append directories:

```nix
    "${configHome}/helix/themes"
    "${configHome}/zed/themes"
```

Append outputs:

```nix
    "${configHome}/helix/themes/matugen.toml"
    "${configHome}/zed/themes/matugen.json"
```

Add template entries:

```nix
      helix = {
        input_path = "${templateDirectory}/helix.toml";
        output_path = "${configHome}/helix/themes/matugen.toml";
      };
      zed = {
        input_path = "${templateDirectory}/zed.json";
        output_path = "${configHome}/zed/themes/matugen.json";
      };
```

Expose both input templates with `xdg.configFile`.

- [ ] **Step 5: Select the generated editor themes**

Delete the `programs.helix.themes.transparent_theme` block from `helix/default.nix` and change `helix/editor.nix` to:

```nix
    theme = "matugen";
```

In `zed.nix`, replace only the existing theme object:

```nix
      theme = {
        mode = "dark";
        dark = "Matugen Dark";
        light = "Matugen Light";
      };
```

- [ ] **Step 6: Run checks**

Run:

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add modules/home/desktop/matugen.nix \
  modules/home/desktop/matugen/templates/helix.toml \
  modules/home/desktop/matugen/templates/zed.json \
  modules/home/programs/helix/default.nix \
  modules/home/programs/helix/editor.nix \
  modules/home/programs/zed.nix \
  tests/configuration.sh
git commit -m "feat: theme editors with matugen"
```

---

### Task 5: Add Isolated Generation Validation and Documentation

**Files:**

- Create: `tests/matugen-generation.sh`
- Modify: `tests/configuration.sh`
- Modify: `README.md`

**Interfaces:**

- Consumes: every managed Matugen template and output declared by Tasks 1-4.
- Produces: one repeatable smoke test proving all templates render outside the real home directory, plus user-facing operational documentation.

- [ ] **Step 1: Add the failing smoke-test call**

At the end of `tests/configuration.sh`, add:

```bash
bash "${repo_root}/tests/matugen-generation.sh" "$flake_ref"
```

- [ ] **Step 2: Run the test and verify failure**

Run `bash tests/configuration.sh`.

Expected: FAIL with `tests/matugen-generation.sh: No such file or directory`.

- [ ] **Step 3: Create the isolated generation test**

Create `tests/matugen-generation.sh` with this structure and exact output set:

```bash
#!/usr/bin/env bash

set -euo pipefail

flake_ref=${1:?flake reference is required}
repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT

test_home="${test_root}/home/itterum"
test_config="${test_home}/.config"
mkdir -p \
  "${test_config}/matugen/templates" \
  "${test_config}/fuzzel" \
  "${test_config}/ghostty/themes" \
  "${test_config}/gtk-3.0" \
  "${test_config}/gtk-4.0" \
  "${test_config}/gtklock" \
  "${test_config}/helix/themes" \
  "${test_config}/niri" \
  "${test_config}/qt5ct/colors" \
  "${test_config}/qt6ct/colors" \
  "${test_config}/zed/themes"
cp "${repo_root}"/modules/home/desktop/matugen/templates/* \
  "${test_config}/matugen/templates/"

matugen_config_source=$(nix build --no-link --print-out-paths \
  "${flake_ref}#nixosConfigurations.laptop.config.home-manager.users.itterum.xdg.configFile.\"matugen/config.toml\".source")
sed "s#/home/itterum#${test_home}#g" \
  "$matugen_config_source" \
  > "${test_config}/matugen/config.toml"
sed -i 's#pkill -SIGUSR2 ghostty || true#true#' \
  "${test_config}/matugen/config.toml"

matugen_package=$(nix build --no-link --print-out-paths \
  "${flake_ref}#nixosConfigurations.laptop.pkgs.matugen")
"${matugen_package}/bin/matugen" \
  image "${repo_root}/assets/wallpapers/nix-wallpaper.png" \
  --config "${test_config}/matugen/config.toml" \
  --mode dark \
  --type scheme-tonal-spot \
  --contrast 0 \
  --source-color-index 0 \
  --quiet

expected_outputs=(
  fuzzel/matugen.ini
  ghostty/themes/Matugen
  gtk-3.0/matugen.css
  gtk-4.0/matugen.css
  gtklock/matugen.css
  helix/themes/matugen.toml
  niri/colors.kdl
  qt5ct/colors/matugen.conf
  qt6ct/colors/matugen.conf
  zed/themes/matugen.json
)

for output in "${expected_outputs[@]}"; do
  path="${test_config}/${output}"
  if [[ ! -s "$path" ]]; then
    printf 'expected generated output: %s\n' "$path" >&2
    exit 1
  fi
  if rg -F '{{' "$path"; then
    printf 'unresolved Matugen expression in: %s\n' "$path" >&2
    exit 1
  fi
done

THEME_FILE="${test_config}/zed/themes/matugen.json" nix eval --json --impure \
  --expr 'builtins.fromJSON (builtins.readFile (builtins.getEnv "THEME_FILE"))' \
  >/dev/null
THEME_FILE="${test_config}/helix/themes/matugen.toml" nix eval --json --impure \
  --expr 'builtins.fromTOML (builtins.readFile (builtins.getEnv "THEME_FILE"))' \
  >/dev/null
```

Append Niri validation by copying evaluated Home Manager sources into the temporary tree:

```bash
niri_base_source=$(nix build --no-link --print-out-paths \
  "${flake_ref}#nixosConfigurations.laptop.config.home-manager.users.itterum.xdg.configFile.niri-config.source")
niri_wrapper_source=$(nix build --no-link --print-out-paths \
  "${flake_ref}#nixosConfigurations.laptop.config.home-manager.users.itterum.xdg.configFile.\"niri/config.kdl\".source")
cp "$niri_base_source" "${test_config}/niri/base.kdl"
cp "$niri_wrapper_source" "${test_config}/niri/config.kdl"
niri_package=$(nix build --no-link --print-out-paths \
  "${flake_ref}#nixosConfigurations.laptop.config.programs.niri.package")
XDG_CONFIG_HOME="$test_config" \
  "${niri_package}/bin/niri" validate \
  --config "${test_config}/niri/config.kdl"
```

The temporary config rewrite above ensures that the test never invokes a generated post-hook against the user's live Ghostty processes.

- [ ] **Step 4: Run the smoke test and correct only observed compatibility issues**

Run:

```bash
bash tests/matugen-generation.sh path:.
bash tests/configuration.sh
```

Expected: all ten files are generated, JSON and TOML parse, no `{{...}}` expressions remain, Niri validates, and both commands PASS.

- [ ] **Step 5: Document operation and reload limitations**

Replace the static Wayle palette paragraph in README's `Declarative desktop settings` section with text covering these exact points:

```markdown
Wayle is the active desktop shell, notification provider, wallpaper controller,
and Matugen palette driver. Changing a wallpaper through Wayle regenerates the
Wayle, Fuzzel, Ghostty, Niri, gtklock, GTK, Qt, Helix, and Zed color files. The
Matugen configuration and input templates are declarative, while generated
theme files under `~/.config` are intentionally mutable runtime state.

Wayle and Niri reload their colors automatically, Ghostty receives its reload
signal, and Fuzzel reads its theme on each launch. GTK, Qt, gtklock, Helix, and
Zed may require a new application instance, manual theme reload, or restart.
The WhiteSur icon theme and macOS cursor remain static.
```

Keep the existing managed-wallpaper statement and QML experiment explanation.

- [ ] **Step 6: Run final verification**

Run in order:

```bash
git diff --check
bash tests/configuration.sh
nix flake check path:. --no-build
nix build --no-link 'path:.#nixosConfigurations.laptop.config.system.build.toplevel'
nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'
```

Expected: every command exits 0. The desktop build may retain the documented bootstrap hardware warning, but it must not fail.

- [ ] **Step 7: Inspect the final diff for generated-state mistakes**

Run:

```bash
git status --short
git diff --stat
git diff -- \
  modules/home/desktop \
  modules/home/programs \
  modules/nixos/desktop/lock.nix \
  tests \
  README.md
```

Expected: no files under `/home/itterum/.config` or other runtime output directories appear in Git; only modules, input templates, tests, and documentation are changed.

- [ ] **Step 8: Commit**

```bash
git add tests/matugen-generation.sh tests/configuration.sh README.md
git commit -m "test: verify matugen desktop generation"
```

---

## Final Review Checklist

- [ ] `modules/home/desktop/matugen.nix` has exactly ten template outputs and the bootstrap output list contains the same ten paths.
- [ ] The bootstrap command and Wayle settings use the same mode, scheme, contrast, and source color index.
- [ ] Only Ghostty has a reload post-hook, and that hook tolerates no running Ghostty process.
- [ ] Wayle still declares its static fallback palette.
- [ ] Niri's typed settings still generate and validate `base.kdl`; only focus-ring colors moved to the mutable include.
- [ ] Home Manager owns every input template and owns none of the generated output paths.
- [ ] Both host evaluations and both NixOS system builds pass.
- [ ] No runtime-generated file or temporary clone is committed.
