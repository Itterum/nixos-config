# Repository Decomposition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish the repository decomposition, replace the maintained Niri KDL file with validated Nix-native settings, keep Wayle active with a repository-managed wallpaper, and split the remaining oversized Home Manager modules.

**Architecture:** Hosts import one NixOS workstation profile and the Home Manager user imports one Home workstation profile. Leaf modules live below `modules/nixos` or `modules/home`, Niri settings are merged from focused Home Manager modules through `niri-flake`, and `experiments` remains outside the production import graph.

**Tech Stack:** NixOS 26.05, Home Manager 26.05, Nix flakes, `sodiboo/niri-flake`, Niri, Wayle, Bash regression checks.

**Spec:** `docs/superpowers/specs/2026-08-29-repository-decomposition-design.md`

## Global Constraints

- Preserve all relevant staged and unstaged user changes already present in the worktree.
- Do not run `nixos-rebuild switch`, restart Niri/greetd/Wayle, or modify the live home directory.
- Keep Wayle active and keep `experiments/**` outside the production import graph.
- Keep the system Niri package from the pinned nixpkgs input; use `niri-flake` only for Home Manager configuration generation and validation.
- Remove bindings that invoke `makoctl`; preserve all other active Niri behavior.
- Use Niri's built-in `recent-windows` defaults because the pinned niri-flake settings schema does not expose that section.
- Install the wallpaper from `assets/wallpapers/nix-wallpaper.png` through Home Manager.
- Use `path:.` for flake commands while new paths are untracked.
- Stage and commit only paths owned by the current task so pre-existing index entries are never swept into an unrelated commit.

## Final File Map

- `flake.nix`: inputs, host construction, Home Manager integration.
- `hosts/{laptop,desktop}/default.nix`: host hardware and host-only policy.
- `profiles/nixos/workstation.nix`: shared NixOS composition root.
- `profiles/home/workstation.nix`: shared Home Manager composition root.
- `home/itterum/default.nix`: user identity and Home profile import.
- `modules/nixos/**`: system services, packages, hardware, session, and containers.
- `modules/home/desktop/default.nix`: desktop composition root.
- `modules/home/desktop/{palette,fuzzel,idle,theme,wayle}.nix`: focused desktop components.
- `modules/home/desktop/niri/**`: generated Niri configuration grouped by responsibility.
- `modules/home/shell/default.nix`: Zsh, Starship, direnv, and general CLI packages.
- `modules/home/programs/{ghostty,zed}.nix`: focused application modules.
- `modules/home/programs/helix/**`: Helix editor and language groups.
- `experiments/itterum-shell/**`: disconnected Quickshell experiment.
- `assets/wallpapers/nix-wallpaper.png`: wallpaper source of truth.
- `tests/configuration.sh`: evaluation and repository-structure regression checks.

---

### Task 1: Establish regression coverage and lock niri-flake

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock`
- Modify: `tests/configuration.sh`

**Interfaces:**
- Consumes: the two existing `nixosConfigurations`, the embedded Home Manager configuration, and the repository filesystem.
- Produces: the locked `inputs.niri-flake` dependency and assertions that describe the final composition before the implementation satisfies them.

- [ ] **Step 1: Record the current broken baseline**

Run:

```bash
bash tests/configuration.sh
```

Expected: FAIL with the current stale import of `modules/network/casting.nix`. Save the error in the task notes; do not repair it before adding the new assertions.

- [ ] **Step 2: Add reusable filesystem assertions and final-state checks**

Add these helpers after `assert_not_contains`:

```bash
assert_file_exists() {
  local path=$1
  [[ -f "$path" ]] || {
    printf 'expected file to exist: %s\n' "$path" >&2
    return 1
  }
}

assert_path_absent() {
  local path=$1
  [[ ! -e "$path" ]] || {
    printf 'expected path to be absent: %s\n' "$path" >&2
    return 1
  }
}
```

Add assertions for these final paths:

```bash
assert_file_exists "${repo_root}/profiles/nixos/workstation.nix"
assert_file_exists "${repo_root}/profiles/home/workstation.nix"
assert_file_exists "${repo_root}/modules/home/desktop/niri/default.nix"
assert_file_exists "${repo_root}/modules/home/programs/helix/default.nix"
assert_file_exists "${repo_root}/experiments/itterum-shell/shell.qml"

assert_path_absent "${repo_root}/modules/profiles"
assert_path_absent "${repo_root}/modules/desktop"
assert_path_absent "${repo_root}/home/itterum/desktop.nix"
assert_path_absent "${repo_root}/home/itterum/files/niri/config.kdl"
assert_path_absent "${repo_root}/experimentals"
```

Replace the old textual KDL read with evaluation of
`home-manager.users.itterum.programs.niri.finalConfig`. Assert that the final
config contains `output \"HDMI-A-1\"`, `spawn \"fuzzel\"`,
`focus-workspace 1`, `move-column-to-monitor-left`, and `screenshot-window`, and
does not contain `makoctl` or `include \"dms/`.

Within the existing host loop, add:

```bash
assert_eq "true" "$(flake_json "$host" "$home_prefix.services.wayle.enable")" "$host Wayle"
assert_eq "false" "$(flake_json "$host" "$home_prefix.services.mako.enable")" "$host Mako disabled"
```

Also evaluate `home-manager.users.itterum.home.file` and assert that its JSON
contains `Pictures/Wallpapers/nix-wallpaper.png`.

- [ ] **Step 3: Run the expanded checks to verify RED**

Run:

```bash
bash tests/configuration.sh
```

Expected: FAIL because final paths are incomplete, Wayle is not imported, and
`programs.niri.finalConfig` is not defined.

- [ ] **Step 4: Add the niri-flake input**

Add this input next to Home Manager:

```nix
niri-flake = {
  url = "github:sodiboo/niri-flake";
  inputs.nixpkgs.follows = "nixpkgs";
};
```

Do not import `niri-flake.nixosModules.niri` and do not enable its Cachix cache.

- [ ] **Step 5: Lock only the new input**

Run:

```bash
nix flake lock --update-input niri-flake
```

Expected: `flake.lock` gains `niri-flake` and its source inputs while existing
direct input revisions remain unchanged.

- [ ] **Step 6: Commit the dependency and RED checks**

```bash
git add -- flake.nix flake.lock tests/configuration.sh
git commit -m "test: define repository decomposition contract"
```

---

### Task 2: Complete the NixOS and Home Manager composition skeleton

**Files:**
- Modify: `hosts/laptop/default.nix`
- Modify: `hosts/desktop/default.nix`
- Create: `profiles/nixos/workstation.nix`
- Create: `profiles/home/workstation.nix`
- Modify: `home/itterum/default.nix`
- Create or move: `modules/nixos/system/base.nix`
- Create or move: `modules/nixos/desktop/{niri,audio,portals,session}.nix`
- Create or move: `modules/nixos/hardware/{bluetooth,nvidia}.nix`
- Create or move: `modules/nixos/network/casting.nix`
- Create or move: `modules/nixos/programs/{browsers,chatgpt}.nix`
- Create or move: `modules/nixos/virtualisation/containers.nix`
- Create: `modules/home/desktop/default.nix`
- Create: `modules/home/shell/default.nix`
- Delete after replacement: old top-level module paths and `home/itterum/{desktop,shell}.nix`

**Interfaces:**
- Consumes: current system leaf modules and current Home Manager monoliths.
- Produces: one import root for NixOS and one for Home Manager, with no stale old-directory imports.

- [ ] **Step 1: Define the NixOS workstation profile**

Write `profiles/nixos/workstation.nix` as:

```nix
{ ... }:

{
  imports = [
    ../../modules/nixos/system/base.nix
    ../../modules/nixos/desktop/niri.nix
    ../../modules/nixos/desktop/audio.nix
    ../../modules/nixos/desktop/portals.nix
    ../../modules/nixos/desktop/session.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/network/casting.nix
    ../../modules/nixos/programs/browsers.nix
    ../../modules/nixos/programs/chatgpt.nix
    ../../modules/nixos/virtualisation/containers.nix
  ];
}
```

Move the current leaf definitions without changing their option values. Fold
the old system `programs/shell.nix` declarations into
`modules/nixos/system/base.nix`:

```nix
programs.zsh.enable = true;
users.users.itterum.shell = pkgs.zsh;
```

Place the ChatGPT module under `modules/nixos/programs/chatgpt.nix` because it
sets `environment.systemPackages`.

- [ ] **Step 2: Point both hosts at the NixOS profile**

Use these imports:

```nix
# laptop
imports = [
  ./hardware-configuration.nix
  ../../profiles/nixos/workstation.nix
];

# desktop
imports = [
  ./hardware-configuration.nix
  ../../profiles/nixos/workstation.nix
  ../../modules/nixos/hardware/nvidia.nix
];
```

Keep hostname, TLP, power-profiles-daemon, and NVIDIA values unchanged.

- [ ] **Step 3: Define the temporary green Home Manager composition**

Move the current contents of `home/itterum/desktop.nix` into
`modules/home/desktop/default.nix` and the current contents of
`home/itterum/shell.nix` into `modules/home/shell/default.nix`. In the temporary
desktop module, change the activation source from `./files/niri/config.kdl` to
`../../../home/itterum/files/niri/config.kdl` so evaluation is restored before
Task 4 removes the activation and source file.

Write `profiles/home/workstation.nix` as:

```nix
{ ... }:

{
  imports = [
    ../../modules/home/desktop
    ../../modules/home/shell
    ../../modules/home/programs/ghostty.nix
    ../../modules/home/programs/helix.nix
    ../../modules/home/programs/zed.nix
  ];
}
```

Write `home/itterum/default.nix` with only the profile import, identity, state
version, and Home Manager enablement:

```nix
{ ... }:

{
  imports = [ ../../profiles/home/workstation.nix ];

  home.username = "itterum";
  home.homeDirectory = "/home/itterum";
  home.stateVersion = "26.05";
  programs.home-manager.enable = true;
}
```

- [ ] **Step 4: Remove replaced old module paths**

Remove only old paths whose content now exists under `modules/nixos` or
`modules/home`. Remove the obsolete Quickshell glue module; retain its QML
sources for Task 5. Do not restore deleted DMS assets or removed Zed themes.

- [ ] **Step 5: Verify both configurations evaluate through the new profiles**

Run:

```bash
nix eval --raw path:.#nixosConfigurations.laptop.config.networking.hostName
nix eval --raw path:.#nixosConfigurations.desktop.config.networking.hostName
rg -n 'modules/(profiles|desktop|hardware|network|programs|system|virtualisation)/' \
  flake.nix hosts profiles home modules --glob '*.nix'
```

Expected: hostnames are `nixos` and `desktop`; `rg` prints no stale production
imports. The complete regression script may still fail on final Home desktop
assertions scheduled for later tasks.

- [ ] **Step 6: Commit the composition skeleton**

Stage the two hosts, both profiles, `home/itterum/default.nix`, all moved system
modules, the temporary Home desktop/shell modules, and replaced old paths only:

```bash
git add -A -- \
  hosts profiles home/itterum/default.nix home/itterum/desktop.nix home/itterum/shell.nix \
  modules/nixos modules/home/desktop/default.nix modules/home/shell \
  modules/desktop modules/hardware modules/network modules/profiles \
  modules/programs modules/system modules/virtualisation
git commit -m "refactor: separate NixOS and Home Manager composition"
```

---

### Task 3: Split the Home desktop and activate Wayle wallpaper ownership

**Files:**
- Modify: `modules/home/desktop/default.nix`
- Create: `modules/home/desktop/palette.nix`
- Create: `modules/home/desktop/fuzzel.nix`
- Create: `modules/home/desktop/idle.nix`
- Create: `modules/home/desktop/theme.nix`
- Modify: `modules/home/desktop/wayle.nix`
- Modify: `modules/home/shell/default.nix`
- Use: `assets/wallpapers/nix-wallpaper.png`

**Interfaces:**
- Consumes: Home Manager `config.home.homeDirectory`, `osConfig.services.tlp.enable`, the shared palette, and the wallpaper asset.
- Produces: focused desktop modules, active Wayle, a managed wallpaper target, and no Mako service.

- [ ] **Step 1: Extract the shared palette**

Write `palette.nix` as a plain attrset:

```nix
{
  base = "1e1e2e";
  mantle = "181825";
  crust = "11111b";
  surface0 = "313244";
  surface1 = "45475a";
  overlay0 = "6c7086";
  text = "cdd6f4";
  subtext0 = "a6adc8";
  mauve = "cba6f7";
  blue = "89b4fa";
  green = "a6e3a1";
  yellow = "f9e2af";
  red = "f38ba8";
}
```

- [ ] **Step 2: Extract Fuzzel, idle/lock, and theme modules**

Move only `programs.fuzzel` into `fuzzel.nix`. Move `programs.swaylock`,
`services.swayidle`, `brightnessctl`, and `playerctl` into `idle.nix`; retain the
TLP-only suspend timeout. Move cursor, GTK, Qt, forced qtct files, and dconf
appearance into `theme.nix`. Each color-using module imports `./palette.nix`.

Move `tree` and `ripgrep` into `modules/home/shell/default.nix`. Do not enable
Mako in any module.

- [ ] **Step 3: Make the desktop default a composition-only module**

Write:

```nix
{ ... }:

{
  imports = [
    ./fuzzel.nix
    ./idle.nix
    ./theme.nix
    ./wayle.nix
    ./niri
  ];
}
```

Until Task 4 completes, `./niri/default.nix` may contain only the temporary KDL
activation moved from the desktop monolith.

- [ ] **Step 4: Enable Wayle and install the wallpaper asset**

In `wayle.nix`, use:

```nix
{
  config,
  ...
}:

let
  palette = import ./palette.nix;
  wallpaperPath = "${config.home.homeDirectory}/Pictures/Wallpapers/nix-wallpaper.png";
in
{
  home.file."Pictures/Wallpapers/nix-wallpaper.png".source =
    ../../../assets/wallpapers/nix-wallpaper.png;

  services.wayle = {
    enable = true;
    autoInstallDependencies = true;
    settings = {
      bar = {
        button-bg-opacity = 0;
        button-variant = "basic";
        layout = [
          {
            center = [ ];
            left = [
              "niri-workspaces"
              "window-title"
            ];
            monitor = "*";
            right = [
              "systray"
              "idle-inhibit"
              "battery"
              "bluetooth"
              "network"
              "microphone"
              "volume"
              "keyboard-input"
              "clock"
              "notifications"
            ];
            show = true;
          }
        ];
        scale = 0.7;
      };
      modules = {
        bluetooth.label-show = false;
        clock = {
          dropdown-show-seconds = true;
          format = "%a %b %d %H:%M:%S";
        };
        keyboard-input.icon-show = false;
        network.label-show = false;
        volume.label-show = false;
      };
      styling = {
        scale = 1;
        palette = {
          bg = "#${palette.crust}";
          elevated = "#${palette.base}";
          fg = "#${palette.text}";
          fg-muted = "#${palette.subtext0}";
          primary = "#${palette.mauve}";
          surface = "#${palette.mantle}";
          blue = "#${palette.blue}";
          green = "#${palette.green}";
          red = "#${palette.red}";
          yellow = "#${palette.yellow}";
        };
      };
      wallpaper = {
        engine-enabled = true;
        cycling-enabled = false;
        monitors = [
          {
            name = "eDP-1";
            wallpaper = wallpaperPath;
            fit-mode = "fill";
          }
        ];
      };
    };
  };
}
```

- [ ] **Step 5: Verify the desktop split**

Run:

```bash
nix eval --json path:.#nixosConfigurations.laptop.config.home-manager.users.itterum.services.wayle.enable
nix eval --json path:.#nixosConfigurations.laptop.config.home-manager.users.itterum.services.mako.enable
nix eval --json path:.#nixosConfigurations.laptop.config.home-manager.users.itterum.home.file
```

Expected: `true`, `false`, and JSON containing
`Pictures/Wallpapers/nix-wallpaper.png` with a Nix-store source derived from the
repository asset.

- [ ] **Step 6: Commit the desktop decomposition**

```bash
git add -- modules/home/desktop modules/home/shell/default.nix assets/wallpapers/nix-wallpaper.png
git commit -m "refactor: split Home Manager desktop modules"
```

---

### Task 4: Replace the Niri KDL source with Nix-native settings

**Files:**
- Create: `modules/home/desktop/niri/default.nix`
- Create: `modules/home/desktop/niri/input.nix`
- Create: `modules/home/desktop/niri/outputs.nix`
- Create: `modules/home/desktop/niri/appearance.nix`
- Create: `modules/home/desktop/niri/animations.nix`
- Create: `modules/home/desktop/niri/rules.nix`
- Create: `modules/home/desktop/niri/binds/{default,applications,media,workspaces,windows,monitors,session}.nix`
- Delete: `home/itterum/files/niri/config.kdl`

**Interfaces:**
- Consumes: `inputs.niri-flake.homeModules.config`, `osConfig.programs.niri.package`, shared palette, and Niri action schema.
- Produces: merged `programs.niri.settings`, validated generated KDL, and `programs.niri.finalConfig` for regression inspection.

- [ ] **Step 1: Wire the niri-flake Home Manager config module**

Write `niri/default.nix` with imports for every Niri leaf and:

```nix
{
  inputs,
  osConfig,
  ...
}:

{
  imports = [
    inputs.niri-flake.homeModules.config
    ./input.nix
    ./outputs.nix
    ./appearance.nix
    ./animations.nix
    ./rules.nix
    ./binds
  ];

  programs.niri = {
    package = osConfig.programs.niri.package;
    settings = {
      config-notification.disable-failed = true;
      hotkey-overlay.skip-at-startup = true;
      environment.XDG_CURRENT_DESKTOP = "niri";
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
      prefer-no-csd = true;
      debug.honor-xdg-activation-with-invalid-serial = [ ];
    };
  };
}
```

- [ ] **Step 2: Convert input and outputs**

`input.nix` sets keyboard numlock, touchpad tap and natural scrolling, macOS
cursor size 24, and disabled hot corners. `outputs.nix` uses typed modes:

```nix
programs.niri.settings.outputs = {
  "HDMI-A-1" = {
    mode = { width = 1920; height = 1080; refresh = 74.973; };
    scale = 1.0;
    position = { x = 0; y = 0; };
  };
  "eDP-1" = {
    mode = { width = 1920; height = 1080; refresh = 60.001; };
    scale = 1.0;
    position = { x = 0; y = 1080; };
  };
};
```

- [ ] **Step 3: Convert appearance and animations**

Set gaps 8, transparent background, `center-focused-column = "never"`, preset
width proportions `0.33333`, `0.5`, `0.66667`, default width `1.0`, focus ring
width 2 with mauve/overlay/red colors, disabled border, enabled shadow with
softness 30, spread 5, offset `(0, 5)`, overview workspace shadow disabled, and
no explicit `recent-windows` settings. Niri's built-in recent-window defaults
replace the current custom highlight and output-scoped Alt+Tab configuration.

Represent each animation using exactly one variant:

```nix
workspace-switch.spring = {
  damping-ratio = 0.8;
  stiffness = 523;
  epsilon = 0.0001;
};

window-open.easing = {
  duration-ms = 150;
  curve = "ease-out-expo";
};
```

Define the remaining animations exactly as follows:

```nix
window-close.easing = { duration-ms = 150; curve = "ease-out-quad"; };
horizontal-view-movement.spring = { damping-ratio = 0.85; stiffness = 423; epsilon = 0.0001; };
window-movement.spring = { damping-ratio = 0.75; stiffness = 323; epsilon = 0.0001; };
window-resize.spring = { damping-ratio = 0.85; stiffness = 423; epsilon = 0.0001; };
config-notification-open-close.spring = { damping-ratio = 0.65; stiffness = 923; epsilon = 0.001; };
screenshot-ui-open.easing = { duration-ms = 200; curve = "ease-out-quad"; };
overview-open-close.spring = { damping-ratio = 0.85; stiffness = 800; epsilon = 0.0001; };
```

- [ ] **Step 4: Convert window and layer rules**

Represent four equal 10-pixel radii explicitly:

```nix
geometry-corner-radius = {
  top-left = 10.0;
  top-right = 10.0;
  bottom-left = 10.0;
  bottom-right = 10.0;
};
```

Convert every active current rule in order: global geometry, WezTerm width,
settings-app half width, floating utility apps, Steam toast placement,
transparent-terminal/browser border behavior, Picture-in-Picture/Zoom floating,
launcher shadow, and awww backdrop placement. Use `matches = [ ... ]` lists to
preserve the KDL rule's OR semantics.

- [ ] **Step 5: Convert application and media bindings**

Use typed actions such as:

```nix
programs.niri.settings.binds = {
  "Mod+Space" = {
    hotkey-overlay.title = "Application Launcher";
    action.spawn = "fuzzel";
  };
  "Mod+Alt+L" = {
    hotkey-overlay.title = "Lock Screen";
    action.spawn = [ "swaylock" "-f" ];
  };
  "XF86AudioRaiseVolume" = {
    allow-when-locked = true;
    action.spawn = [ "wpctl" "set-volume" "-l" "1.0" "@DEFAULT_AUDIO_SINK@" "3%+" ];
  };
};
```

Keep Fuzzel, swaylock, Ghostty, btop, wpctl, playerctl, and brightnessctl binds.
Do not add `Mod+N` or `Mod+Shift+N` because their current actions call Mako.

- [ ] **Step 6: Convert workspace, window, monitor, layout, and session bindings**

Split the remaining active bindings by behavior. Preserve every current key,
action argument, `repeat`, `cooldown-ms`, `allow-when-locked`, and
`allow-inhibiting` flag. The mapping is:

```text
workspaces.nix: Mod+1..9, Mod+Shift+1..9, I/U, Page_Up/Page_Down, workspace wheel actions
windows.nix: H/J/K/L, arrows, Home/End, window/column movement, sizing and layout actions
monitors.nix: monitor focus and move-column-to-monitor actions
session.nix: screenshots, overview, monitor power, inhibit toggle, overlay, quit
```

`binds/default.nix` imports the six bind groups and contains no bindings itself.

- [ ] **Step 7: Delete the maintained KDL and verify generated output**

Remove the KDL activation and `home/itterum/files/niri/config.kdl`. Run:

```bash
nix eval --raw path:.#nixosConfigurations.laptop.config.home-manager.users.itterum.programs.niri.finalConfig > /tmp/niri-generated.kdl
nix eval --raw path:.#nixosConfigurations.desktop.config.home-manager.users.itterum.programs.niri.finalConfig > /tmp/niri-generated-desktop.kdl
niri_package=$(nix eval --raw path:.#nixosConfigurations.laptop.config.programs.niri.package)
"${niri_package}/bin/niri" validate -c /tmp/niri-generated.kdl
```

Expected: both evaluations succeed and validation exits 0.

- [ ] **Step 8: Run focused regression checks and commit**

```bash
bash tests/configuration.sh
git add -- modules/home/desktop/niri home/itterum/files/niri tests/configuration.sh
git commit -m "refactor: configure Niri with native Nix settings"
```

Expected: Niri and desktop assertions pass. Any remaining failure must belong to
the Helix/experiments cleanup in Task 5, not Niri evaluation.

---

### Task 5: Split Helix and isolate experiments

**Files:**
- Create: `modules/home/programs/helix/default.nix`
- Create: `modules/home/programs/helix/editor.nix`
- Create: `modules/home/programs/helix/languages/{default,web,rust,python,misc}.nix`
- Delete: `modules/home/programs/helix.nix`
- Modify: `profiles/home/workstation.nix`
- Move: `experimentals/itterum-shell/**` to `experiments/itterum-shell/**`
- Delete: empty intermediate files

**Interfaces:**
- Consumes: the current Helix settings, language-server definitions, language list, theme, and extra packages.
- Produces: mergeable focused Helix modules and a disconnected experiments tree.

- [ ] **Step 1: Create the Helix composition and editor module**

`helix/default.nix` imports `editor.nix` and `languages`, enables Helix, sets it
as the default editor, defines `catppuccin_mocha_transparent`, and owns the
combined `extraPackages` list. `editor.nix` owns only `programs.helix.settings`:
theme selection, editor behavior, statusline, cursor shapes, file picker, and
normal/insert keymaps.

- [ ] **Step 2: Split language declarations by ecosystem**

Use this exact ownership:

```text
web.nix: typescript-language-server; typescript, tsx, javascript, jsx
rust.nix: rust-analyzer; rust
python.nix: basedpyright and ruff; python
misc.nix: csharp-ls, qmlls, JSON, taplo, marksman, Bash, nixd; C#, QML, JSON, TOML, Markdown, Bash, Nix, KDL
```

Each file sets only its entries under `programs.helix.languages.language-server`
and its own portion of `programs.helix.languages.language`. Verify that Home
Manager concatenates the language lists and merges the server attrsets.

- [ ] **Step 3: Update the Home profile and verify Helix**

Change the profile import from `../../modules/home/programs/helix.nix` to
`../../modules/home/programs/helix`. Run:

```bash
nix eval --json path:.#nixosConfigurations.laptop.config.home-manager.users.itterum.programs.helix.enable
nix eval --json path:.#nixosConfigurations.laptop.config.home-manager.users.itterum.programs.helix.languages.language
```

Expected: enabled is `true`; the language JSON contains `typescript`, `rust`,
`python`, `c-sharp`, `nix`, `qml`, `json`, `toml`, `markdown`, `bash`, and `kdl`
exactly once each.

- [ ] **Step 4: Normalize the experiments path**

Move the current QML files to `experiments/itterum-shell`. Remove
`experimentals/`, the old top-level `itterum-shell/`, and obsolete Quickshell
Nix modules only after confirming the three experiment files exist at the new
path.

Run:

```bash
rg -n 'experiments|experimentals|itterum-shell|quickshell' \
  flake.nix hosts profiles home modules --glob '*.nix'
```

Expected: no output. References inside the experiment's own QML files are
allowed because the directory is outside the searched production roots.

- [ ] **Step 5: Commit Helix and experiments**

```bash
git add -A -- modules/home/programs/helix profiles/home/workstation.nix experiments experimentals itterum-shell
git commit -m "refactor: split Helix and isolate desktop experiments"
```

---

### Task 6: Update documentation and perform full verification

**Files:**
- Modify: `README.md`
- Inspect: all files in the final tree

**Interfaces:**
- Consumes: the completed NixOS/Home Manager decomposition.
- Produces: accurate repository documentation and evidence that both host closures build.

- [ ] **Step 1: Update README ownership and paths**

Replace old `modules/hardware/nvidia.nix` and mutable checked-in KDL/DMS text
with the final `modules/nixos/hardware/nvidia.nix`, profile structure,
Nix-generated Niri configuration, active Wayle shell, managed wallpaper, and
disconnected `experiments/` explanation. Keep the desktop bootstrap and install
warnings intact.

- [ ] **Step 2: Format changed source files**

Run the formatter from nixpkgs over every changed `.nix` file:

```bash
nix fmt -- $(git diff --name-only --diff-filter=ACMR | rg '\.nix$')
```

If `nix fmt` does not accept path arguments for this flake, evaluate the
formatter path and invoke its `bin/nixfmt` executable with the same file list.
Do not run KDL formatting because no maintained KDL file remains.

- [ ] **Step 3: Run static and regression checks**

```bash
bash tests/configuration.sh
nix flake check path:. --no-build
git diff --check
```

Expected: all commands exit 0. Report upstream deprecation or dirty-tree
warnings separately; do not classify them as repository failures.

- [ ] **Step 4: Build both systems**

```bash
nix build --no-link 'path:.#nixosConfigurations.laptop.config.system.build.toplevel'
nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'
```

Expected: both commands exit 0 without activating either result.

- [ ] **Step 5: Inspect the final import graph and tree**

```bash
find hosts profiles modules home assets experiments tests -type f | sort
rg -n 'modules/(profiles|desktop|hardware|network|programs|system|virtualisation)/' \
  flake.nix hosts profiles home modules --glob '*.nix'
rg -n 'experiments|experimentals|itterum-shell|config\.kdl|makoctl|dms/' \
  flake.nix hosts profiles home modules tests README.md
git status --short
git diff --stat HEAD
```

Expected: the first `rg` has no output; the second has only intentional
documentation/test assertions and generated-config target names from
`niri-flake`, never a maintained KDL source or production experiment import.
Confirm there are no empty `.nix` files and no unrelated changes were reverted.

- [ ] **Step 6: Commit documentation and verification adjustments**

```bash
git add -- README.md tests/configuration.sh
git commit -m "docs: document decomposed NixOS configuration"
```

Only create this commit when at least one of those files changed in Task 6. Do
not create an empty commit.
