# NixOS Laptop Skeleton Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Перенести текущую рабочую конфигурацию ноутбука в `/home/itterum/nixos-config`, подключить минимальный Home Manager и включить исправный Bluetooth через BlueZ без потери Niri/DMS и пользовательских настроек.

**Architecture:** Сначала создаётся семантически эквивалентный текущей системе flake с host-модулем `laptop` и небольшими системными модулями. Затем отдельно подключается Home Manager без захвата существующих dotfiles, сохраняются резервные снимки пользовательских конфигов и одним изолированным модулем включается Bluetooth. Активация выполняется только после flake check, полной сборки, сравнения критических опций и проверки closure diff.

**Tech Stack:** NixOS 26.05, Nix flakes, Home Manager release-26.05, Niri 26.04, DankMaterialShell 1.4.6, greetd, PipeWire, BlueZ, Git.

**Spec:** `docs/superpowers/specs/2026-08-26-nixos-skeleton-design.md`

## Global Constraints

- Канонический репозиторий: `/home/itterum/nixos-config`.
- Исходный `/etc/nixos` не изменять и не удалять.
- Сохранить `networking.hostName = "nixos"` и `system.stateVersion = "26.05"`.
- Не обновлять существующие locked revisions `nixpkgs` и `llm-agents`; разрешено только добавить lock-узлы Home Manager.
- Не устанавливать Podman, Distrobox, Zsh, Starship, Zed, Obsidian или JetBrains Toolbox на первом этапе.
- Не передавать Home Manager владение существующими Niri, DMS и Ghostty файлами на первом этапе.
- Не выполнять `switch`, пока flake check, build, option parity и Bluetooth evaluation не успешны.
- После каждой самостоятельной конфигурационной задачи создавать Git-коммит.
- Для коммитов агента использовать одноразовые параметры `-c user.name=Codex -c user.email=codex@local`, не изменяя Git identity пользователя.
- При любой ошибке до активации остановиться; при критической ошибке после активации переключиться на предыдущую NixOS-генерацию.

## File Map

- `flake.nix` — inputs и единственный system output `nixosConfigurations.laptop`.
- `flake.lock` — исходные locked revisions плюс Home Manager после Task 2.
- `hosts/laptop/default.nix` — композиция модулей конкретного ноутбука.
- `hosts/laptop/hardware-configuration.nix` — неизменённый результат hardware scan.
- `modules/system/base.nix` — boot, сеть, locale, пользователь, Nix, power/storage services и базовые пакеты.
- `modules/hardware/bluetooth.nix` — единственное изменение поведения первого этапа: включение BlueZ.
- `modules/desktop/niri.nix` — Niri.
- `modules/desktop/dms.nix` — DMS и DMS Greeter/greetd.
- `modules/desktop/portals.nix` — явное включение portal framework; реализации остаются предоставлены Niri/NixOS.
- `modules/desktop/audio.nix` — текущая PipeWire/WirePlumber конфигурация.
- `modules/programs/browsers.nix` — Brave и Google Chrome.
- `modules/programs/chatgpt.nix` — ChatGPT из `llm-agents.nix`.
- `home/itterum/default.nix` — минимальный Home Manager без управления dotfiles.
- `home/itterum/files/niri/config.kdl` — резервный снимок пользовательского Niri config.
- `home/itterum/files/dms/settings.json` — резервный снимок настроек DMS.
- `home/itterum/files/dms/themes/catppuccin/` — резервный снимок пользовательской темы DMS.
- `home/itterum/files/ghostty/config` — резервный снимок Ghostty config.

---

### Task 1: Создать модульный flake с полным паритетом текущей системы

**Files:**
- Create: `flake.nix`
- Create: `flake.lock` by copying `/etc/nixos/flake.lock`
- Create: `hosts/laptop/default.nix`
- Create: `hosts/laptop/hardware-configuration.nix` by copying `/etc/nixos/hardware-configuration.nix`
- Create: `modules/system/base.nix`
- Create: `modules/desktop/niri.nix`
- Create: `modules/desktop/dms.nix`
- Create: `modules/desktop/portals.nix`
- Create: `modules/desktop/audio.nix`
- Create: `modules/programs/browsers.nix`
- Create: `modules/programs/chatgpt.nix`

**Interfaces:**
- Consumes: `/etc/nixos/flake.lock`, `/etc/nixos/configuration.nix`, `/etc/nixos/hardware-configuration.nix` and the locked `llm-agents.packages.x86_64-linux.chatgpt` output.
- Produces: `nixosConfigurations.laptop` whose critical options and package-name set match `/etc/nixos#nixosConfigurations.nixos` before Home Manager and Bluetooth are introduced.

- [ ] **Step 1: Зафиксировать ожидаемый failure до появления flake**

Run:

```bash
cd /home/itterum/nixos-config
nix flake check . --no-build
```

Expected: FAIL because repository root has no `flake.nix`.

- [ ] **Step 2: Скопировать locked inputs и hardware scan**

Run:

```bash
cd /home/itterum/nixos-config
mkdir -p hosts/laptop modules/system modules/hardware modules/desktop modules/programs home/itterum/files
cp /etc/nixos/flake.lock ./flake.lock
cp /etc/nixos/hardware-configuration.nix ./hosts/laptop/hardware-configuration.nix
cmp /etc/nixos/hardware-configuration.nix ./hosts/laptop/hardware-configuration.nix
```

Expected: `cmp` exits 0 with no output.

- [ ] **Step 3: Создать flake без Home Manager**

Create `flake.nix`:

```nix
{
  description = "Itterum NixOS laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = inputs@{ nixpkgs, ... }: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [ ./hosts/laptop ];
    };
  };
}
```

- [ ] **Step 4: Создать host composition**

Create `hosts/laptop/default.nix`:

```nix
{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/system/base.nix
    ../../modules/desktop/niri.nix
    ../../modules/desktop/dms.nix
    ../../modules/desktop/portals.nix
    ../../modules/desktop/audio.nix
    ../../modules/programs/browsers.nix
    ../../modules/programs/chatgpt.nix
  ];
}
```

- [ ] **Step 5: Создать base system module**

Create `modules/system/base.nix`:

```nix
{ pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "ctrl:nocaps,grp:shifts_toggle";
  };

  users.users.itterum = {
    isNormalUser = true;
    description = "itterum";
    extraGroups = [ "networkmanager" "wheel" ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    helix
    foot
    greetd
    ghostty
    keepassxc
    nautilus
  ];

  services.tlp.enable = true;
  services.power-profiles-daemon.enable = false;
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  system.stateVersion = "26.05";
}
```

- [ ] **Step 6: Создать desktop modules**

Create `modules/desktop/niri.nix`:

```nix
{ ... }:

{
  programs.niri.enable = true;
}
```

Create `modules/desktop/dms.nix`:

```nix
{ ... }:

{
  programs.dms-shell.enable = true;

  services.displayManager = {
    defaultSession = "niri";
    autoLogin.enable = false;

    dms-greeter = {
      enable = true;
      compositor.name = "niri";
      configHome = "/home/itterum";
      logs.save = true;
    };
  };
}
```

Create `modules/desktop/portals.nix`:

```nix
{ ... }:

{
  xdg.portal.enable = true;
}
```

Create `modules/desktop/audio.nix`:

```nix
{ ... }:

{
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };
}
```

- [ ] **Step 7: Создать program modules**

Create `modules/programs/browsers.nix`:

```nix
{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    brave
    google-chrome
  ];
}
```

Create `modules/programs/chatgpt.nix`:

```nix
{ inputs, pkgs, ... }:

{
  environment.systemPackages = [
    inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}.chatgpt
  ];
}
```

- [ ] **Step 8: Проверить flake и точный system parity**

Run:

```bash
cd /home/itterum/nixos-config
nix flake check . --no-build
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link --print-out-paths
```

Then verify semantic parity:

```bash
nix eval --impure --json --expr '
let
  oldFlake = builtins.getFlake "/etc/nixos";
  newFlake = builtins.getFlake "/home/itterum/nixos-config";
  old = oldFlake.nixosConfigurations.nixos.config;
  new = newFlake.nixosConfigurations.laptop.config;
  names = flake: cfg:
    builtins.sort builtins.lessThan
      (map flake.inputs.nixpkgs.lib.getName cfg.environment.systemPackages);
in {
  hostname = old.networking.hostName == new.networking.hostName;
  stateVersion = old.system.stateVersion == new.system.stateVersion;
  niri = old.programs.niri.enable == new.programs.niri.enable;
  dms = old.programs.dms-shell.enable == new.programs.dms-shell.enable;
  greeter = old.services.displayManager.dms-greeter.enable == new.services.displayManager.dms-greeter.enable;
  pipewire = old.services.pipewire.enable == new.services.pipewire.enable;
  portal = old.xdg.portal.enable == new.xdg.portal.enable;
  packages = names oldFlake old == names newFlake new;
}'
```

Expected: build succeeds and every parity field prints `true`. The store path may differ because module list definitions can merge in a different order; an unexplained package or option difference is a stop condition.

- [ ] **Step 9: Commit parity skeleton**

Run:

```bash
cd /home/itterum/nixos-config
git add flake.nix flake.lock hosts modules
git -c user.name=Codex -c user.email=codex@local commit -m "feat: add modular laptop configuration"
```

---

### Task 2: Подключить минимальный Home Manager

**Files:**
- Modify: `flake.nix`
- Modify: `flake.lock` through `nix flake lock`
- Create: `home/itterum/default.nix`

**Interfaces:**
- Consumes: `inputs.nixpkgs` and `nixosConfigurations.laptop` from Task 1.
- Produces: Home Manager generation for user `itterum` integrated into the NixOS build, without declaring `xdg.configFile`, `home.file`, shell changes or user packages.

- [ ] **Step 1: Проверить отсутствие Home Manager input**

Run:

```bash
cd /home/itterum/nixos-config
nix eval --impure --raw --expr '(builtins.getFlake "/home/itterum/nixos-config").inputs.home-manager.outPath'
```

Expected: FAIL because the input does not exist.

- [ ] **Step 2: Добавить Home Manager input и NixOS module**

Modify `flake.nix` to:

```nix
{
  description = "Itterum NixOS laptop";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    llm-agents.url = "github:numtide/llm-agents.nix";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, home-manager, ... }: {
    nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };

      modules = [
        ./hosts/laptop
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.extraSpecialArgs = { inherit inputs; };
          home-manager.users.itterum = import ./home/itterum;
        }
      ];
    };
  };
}
```

- [ ] **Step 3: Создать минимальный user module**

Create `home/itterum/default.nix`:

```nix
{ ... }:

{
  home.username = "itterum";
  home.homeDirectory = "/home/itterum";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;
}
```

- [ ] **Step 4: Добавить только Home Manager lock nodes**

Run:

```bash
cd /home/itterum/nixos-config
nix flake lock
nix flake metadata --json .
```

Expected: existing nixpkgs revision remains `f4f698677b11021a8f84f452e23ae9ef2427bec3`; existing llm-agents revision remains `76b78a399417964e9133aed0c0a9493616c3508e`; Home Manager resolves from `release-26.05` and follows root nixpkgs.

- [ ] **Step 5: Проверить минимальную Home Manager сборку**

Run:

```bash
cd /home/itterum/nixos-config
nix flake check . --no-build
nix eval --impure --raw --expr '(builtins.getFlake "/home/itterum/nixos-config").inputs.home-manager.outPath'
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link --print-out-paths
```

Expected: all commands succeed; system path may differ from Task 1 because a Home Manager generation is now integrated.

- [ ] **Step 6: Commit Home Manager integration**

Run:

```bash
cd /home/itterum/nixos-config
git add flake.nix flake.lock home/itterum/default.nix
git -c user.name=Codex -c user.email=codex@local commit -m "feat: integrate minimal Home Manager"
```

---

### Task 3: Сохранить пользовательские конфиги без передачи владения Home Manager

**Files:**
- Create: `home/itterum/files/niri/config.kdl`
- Create: `home/itterum/files/dms/settings.json`
- Create: `home/itterum/files/dms/themes/catppuccin/preview-dark.svg`
- Create: `home/itterum/files/dms/themes/catppuccin/preview-light.svg`
- Create: `home/itterum/files/dms/themes/catppuccin/theme.json`
- Create: `home/itterum/files/ghostty/config`

**Interfaces:**
- Consumes: current mutable files under `/home/itterum/.config`.
- Produces: versioned restoration snapshots that are not referenced by `home/itterum/default.nix`, so DMS and Ghostty continue using writable live files.

- [ ] **Step 1: Проверить отсутствие snapshots**

Run:

```bash
cd /home/itterum/nixos-config
test ! -e home/itterum/files/niri/config.kdl
test ! -e home/itterum/files/dms/settings.json
test ! -e home/itterum/files/ghostty/config
```

Expected: all commands exit 0.

- [ ] **Step 2: Скопировать только пользовательские и theme файлы**

Run:

```bash
cd /home/itterum/nixos-config
mkdir -p home/itterum/files/niri
mkdir -p home/itterum/files/dms/themes
mkdir -p home/itterum/files/ghostty
cp /home/itterum/.config/niri/config.kdl home/itterum/files/niri/config.kdl
cp /home/itterum/.config/DankMaterialShell/settings.json home/itterum/files/dms/settings.json
cp -R /home/itterum/.config/DankMaterialShell/themes/catppuccin home/itterum/files/dms/themes/catppuccin
cp /home/itterum/.config/ghostty/config home/itterum/files/ghostty/config
```

Do not copy `~/.config/niri/dms`, DMS session/cache files, browser data or the old Niri backup file.

- [ ] **Step 3: Проверить byte-for-byte snapshots и отсутствие Home Manager ownership**

Run:

```bash
cd /home/itterum/nixos-config
cmp /home/itterum/.config/niri/config.kdl home/itterum/files/niri/config.kdl
cmp /home/itterum/.config/DankMaterialShell/settings.json home/itterum/files/dms/settings.json
cmp /home/itterum/.config/ghostty/config home/itterum/files/ghostty/config
rg -n 'xdg\.configFile|home\.file' home/itterum/default.nix
```

Expected: all `cmp` commands exit 0; `rg` returns no matches.

- [ ] **Step 4: Commit configuration snapshots**

Run:

```bash
cd /home/itterum/nixos-config
git add home/itterum/files
git -c user.name=Codex -c user.email=codex@local commit -m "backup: preserve current desktop configuration"
```

---

### Task 4: Включить BlueZ изолированным Bluetooth-модулем

**Files:**
- Create: `modules/hardware/bluetooth.nix`
- Modify: `hosts/laptop/default.nix`

**Interfaces:**
- Consumes: working kernel adapter `hci0`, NixOS `hardware.bluetooth` module and DMS D-Bus integration.
- Produces: `hardware.bluetooth.enable = true`, BlueZ 5.86 in the system closure, `bluetooth.service`, `bluetoothctl` and automatic controller power-on through the existing `powerOnBoot = true` default.

- [ ] **Step 1: Verify the failing declarative state**

Run:

```bash
cd /home/itterum/nixos-config
nix eval --json .#nixosConfigurations.laptop.config.hardware.bluetooth.enable
nix eval --json .#nixosConfigurations.laptop.config.systemd.services.bluetooth
```

Expected: first command prints `false`; second command fails because the service is not defined.

- [ ] **Step 2: Create the minimal Bluetooth module**

Create `modules/hardware/bluetooth.nix`:

```nix
{ ... }:

{
  hardware.bluetooth.enable = true;
}
```

- [ ] **Step 3: Import the Bluetooth module**

Add this line after `../../modules/system/base.nix` in `hosts/laptop/default.nix`:

```nix
    ../../modules/hardware/bluetooth.nix
```

- [ ] **Step 4: Verify BlueZ evaluation**

Run:

```bash
cd /home/itterum/nixos-config
nix eval --json .#nixosConfigurations.laptop.config.hardware.bluetooth.enable
nix eval --json .#nixosConfigurations.laptop.config.hardware.bluetooth.powerOnBoot
nix eval --raw .#nixosConfigurations.laptop.config.hardware.bluetooth.package.name
nix eval --json .#nixosConfigurations.laptop.config.systemd.services.bluetooth.wantedBy
```

Expected outputs: `true`, `true`, `bluez-5.86`, and a list containing `bluetooth.target`.

- [ ] **Step 5: Build the Bluetooth-enabled system**

Run:

```bash
cd /home/itterum/nixos-config
nix flake check . --no-build
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link --print-out-paths
```

Expected: both commands succeed.

- [ ] **Step 6: Commit Bluetooth support**

Run:

```bash
cd /home/itterum/nixos-config
git add hosts/laptop/default.nix modules/hardware/bluetooth.nix
git -c user.name=Codex -c user.email=codex@local commit -m "feat: enable laptop Bluetooth"
```

---

### Task 5: Выполнить полную pre-switch проверку

**Files:**
- No file changes expected.

**Interfaces:**
- Consumes: committed configuration from Tasks 1–4 and active `/run/current-system`.
- Produces: one verified candidate store path safe to activate.

- [ ] **Step 1: Verify clean repository and lock consistency**

Run:

```bash
cd /home/itterum/nixos-config
git status --short
nix flake check .
```

Expected: Git status has no output and flake check succeeds.

- [ ] **Step 2: Build and capture the candidate path without activation**

Run:

```bash
cd /home/itterum/nixos-config
nix build .#nixosConfigurations.laptop.config.system.build.toplevel --no-link --print-out-paths | tee /tmp/nixos-skeleton-candidate-path
test -d "$(cat /tmp/nixos-skeleton-candidate-path)"
```

Expected: exactly one valid `/nix/store/...-nixos-system-nixos-26.05...` path.

- [ ] **Step 3: Compare critical old and new options**

Run:

```bash
nix eval --impure --json --expr '
let
  old = (builtins.getFlake "/etc/nixos").nixosConfigurations.nixos.config;
  new = (builtins.getFlake "/home/itterum/nixos-config").nixosConfigurations.laptop.config;
in {
  hostname = { old = old.networking.hostName; new = new.networking.hostName; };
  stateVersion = { old = old.system.stateVersion; new = new.system.stateVersion; };
  niri = { old = old.programs.niri.enable; new = new.programs.niri.enable; };
  dms = { old = old.programs.dms-shell.enable; new = new.programs.dms-shell.enable; };
  greeter = { old = old.services.displayManager.dms-greeter.enable; new = new.services.displayManager.dms-greeter.enable; };
  session = { old = old.services.displayManager.defaultSession; new = new.services.displayManager.defaultSession; };
  pipewire = { old = old.services.pipewire.enable; new = new.services.pipewire.enable; };
  pulse = { old = old.services.pipewire.pulse.enable; new = new.services.pipewire.pulse.enable; };
  wireplumber = { old = old.services.pipewire.wireplumber.enable; new = new.services.pipewire.wireplumber.enable; };
  portal = { old = old.xdg.portal.enable; new = new.xdg.portal.enable; };
  bluetooth = { old = old.hardware.bluetooth.enable; new = new.hardware.bluetooth.enable; };
}'
```

Expected: every old/new pair is equal except Bluetooth, which changes from `false` to `true`.

- [ ] **Step 4: Inspect closure changes**

Run:

```bash
nix store diff-closures /run/current-system "$(cat /tmp/nixos-skeleton-candidate-path)"
```

Expected: additions attributable to Home Manager and BlueZ; no unexplained removal of Niri, DMS, PipeWire, browsers, Ghostty, Helix or ChatGPT.

- [ ] **Step 5: Revalidate live user configs before activation**

Run:

```bash
niri validate -c /home/itterum/.config/niri/config.kdl
cmp /home/itterum/.config/niri/config.kdl /home/itterum/nixos-config/home/itterum/files/niri/config.kdl
cmp /home/itterum/.config/DankMaterialShell/settings.json /home/itterum/nixos-config/home/itterum/files/dms/settings.json
cmp /home/itterum/.config/ghostty/config /home/itterum/nixos-config/home/itterum/files/ghostty/config
```

Expected: all commands exit 0.

---

### Task 6: Activate once and verify the live system

**Files:**
- No configuration file changes expected.

**Interfaces:**
- Consumes: candidate system path validated by Task 5.
- Produces: active NixOS generation built from `#laptop`, minimal Home Manager profile and working BlueZ adapter visible to DMS.

- [ ] **Step 1: Verify sudo availability without prompting**

Run:

```bash
sudo -n true
```

Expected: exits 0. If it fails, stop and ask the user to run the activation command interactively; do not request or capture their password.

- [ ] **Step 2: Perform the only system switch**

Run:

```bash
cd /home/itterum/nixos-config
sudo -n nixos-rebuild switch --flake .#laptop
```

Expected: build and activation succeed with no failed unit.

- [ ] **Step 3: Verify active generation and core services**

Run:

```bash
readlink -f /run/current-system
cat /tmp/nixos-skeleton-candidate-path
systemctl is-active greetd.service bluetooth.service
systemctl --user is-active niri.service dms.service pipewire.service pipewire-pulse.service wireplumber.service xdg-desktop-portal.service
```

Expected: active system equals the candidate path; every service reports `active`.

- [ ] **Step 4: Verify Home Manager activation without dotfile takeover**

Run:

```bash
readlink -f /home/itterum/.local/state/nix/profiles/home-manager
test ! -L /home/itterum/.config/niri/config.kdl
test ! -L /home/itterum/.config/DankMaterialShell/settings.json
test ! -L /home/itterum/.config/ghostty/config
```

Expected: Home Manager profile resolves to a store generation; all three live configs remain ordinary writable files.

- [ ] **Step 5: Verify Bluetooth controller and discovery**

Run:

```bash
bluetoothctl list
bluetoothctl show
bluetoothctl power on
bluetoothctl --timeout 15 scan on
```

Expected: `hci0` is represented by a BlueZ controller, `Powered: yes`, and discovery starts without `No default controller available`. Nearby discoverable devices appear when present.

- [ ] **Step 6: Run final desktop health checks**

Run:

```bash
niri validate -c /home/itterum/.config/niri/config.kdl
dms doctor
systemctl --failed --no-pager
systemctl --user --failed --no-pager
git -C /home/itterum/nixos-config status --short --branch
```

Expected: Niri validates; DMS reports Niri/DMS/greetd available; no new failed units; repository remains clean on `main`.

- [ ] **Step 7: Roll back only if a critical runtime check fails**

Run only when greetd, Niri, DMS, PipeWire or login is broken:

```bash
sudo -n nixos-rebuild switch --rollback
```

Expected: `/run/current-system` returns to the previous generation. Keep `/home/itterum/nixos-config` intact for diagnosis; `/etc/nixos` remains the known-good source.
