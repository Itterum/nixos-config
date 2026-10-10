# Limine Stage 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace systemd-boot with unsigned Limine on the `pc` host while preserving systemd-boot as a firmware-level fallback and stopping before reboot.

**Architecture:** A focused `pcBoot` NixOS module will own every boot-loader setting. An evaluation test will pin the mutually exclusive loader configuration and safety defaults; runtime checks around `nixos-rebuild switch` will prove that Limine was installed on the ESP without removing the previous systemd-boot fallback.

**Tech Stack:** NixOS modules, Limine, UEFI/efibootmgr, Bash, jq

**Spec:** `docs/superpowers/specs/2026-10-10-limine-secure-boot-design.md`

## Global Constraints

- Stage 1 only: Limine Secure Boot signing remains disabled and no keys are created or enrolled.
- The machine uses UEFI and the FAT32 ESP mounted at `/boot`; BIOS installation remains disabled.
- Do not reboot the machine automatically.
- Do not remove the existing systemd-boot EFI binary or `Linux Boot Manager` firmware entry.
- Limine's boot-entry editor remains disabled.
- Limine retains at most 10 NixOS generations.
- Private Secure Boot keys must never enter Git or the Nix store.

## Review Focus

- Loader conflict: evaluation must prove Limine is enabled while systemd-boot is disabled.
- Wrong firmware mode: evaluation must prove UEFI is enabled, BIOS is disabled, and removable-path installation is disabled.
- Premature security transition: evaluation must prove Secure Boot signing, automatic key generation, and automatic key enrollment are all disabled.
- Unbounded boot files: evaluation must prove Limine's generation limit is 10 after removing the systemd-boot-specific limit.
- Lost recovery path: runtime validation must prove both the new Limine EFI entry/files and the previous systemd-boot EFI entry/files coexist before reboot.

---

### Task 1: Declarative Limine Boot Module

**Files:**
- Create: `tests/boot.sh`
- Create: `modules/hosts/pc/boot.nix`
- Modify: `modules/hosts/pc/configuration.nix:5-19,42-43`
- Modify: `modules/hosts/pc/maintenance.nix:10-11`
- Modify: `tests/maintenance.sh:5-21`

**Interfaces:**
- Consumes: `flake.nixosConfigurations.pc.config` and the repository's `flake.nixosModules.pc*` import pattern.
- Produces: `flake.nixosModules.pcBoot`, with evaluated `boot.loader.limine`, `boot.loader.systemd-boot`, and `boot.loader.efi` settings used by Task 2.

- [ ] **Step 1: Write the failing boot-loader evaluation test**

Create `tests/boot.sh`. Evaluate the `pc` configuration into JSON and assert with `jq`:

- `boot.loader.systemd-boot.enable == false`;
- `boot.loader.limine.enable == true`;
- `boot.loader.limine.efiSupport == true`;
- `boot.loader.limine.biosSupport == false`;
- `boot.loader.limine.efiInstallAsRemovable == false`;
- `boot.loader.limine.enableEditor == false`;
- `boot.loader.limine.maxGenerations == 10`;
- `boot.loader.limine.secureBoot.enable == false`;
- `boot.loader.limine.secureBoot.autoGenerateKeys == false`;
- `boot.loader.limine.secureBoot.autoEnrollKeys.enable == false`;
- `boot.loader.efi.canTouchEfiVariables == true`.

The script prints `Limine boot configuration assertions passed` only after all assertions succeed.

- [ ] **Step 2: Run the new test and verify the expected failure**

Run: `bash tests/boot.sh`

Expected: exit status 1 because systemd-boot is enabled and Limine is disabled.

- [ ] **Step 3: Remove the loader-specific assertion from the maintenance test**

Update `tests/maintenance.sh` to evaluate and assert only `nix.gc.automatic`, `nix.gc.dates`, and `nix.gc.options`. Boot generation retention belongs to `tests/boot.sh` after the migration.

- [ ] **Step 4: Create and connect the boot module**

Create `modules/hosts/pc/boot.nix` exporting `flake.nixosModules.pcBoot`. Set these exact values:

```nix
boot.loader = {
  systemd-boot.enable = false;
  efi.canTouchEfiVariables = true;

  limine = {
    enable = true;
    efiSupport = true;
    efiInstallAsRemovable = false;
    biosSupport = false;
    enableEditor = false;
    maxGenerations = 10;
    secureBoot.enable = false;
  };
};
```

Import `self.nixosModules.pcBoot` from `modules/hosts/pc/configuration.nix`, remove the old systemd-boot and EFI lines there, and remove `boot.loader.systemd-boot.configurationLimit` from `modules/hosts/pc/maintenance.nix`.

- [ ] **Step 5: Run focused tests**

Run: `bash tests/boot.sh && bash tests/maintenance.sh`

Expected: both scripts exit 0 and print their success messages.

- [ ] **Step 6: Run formatting, the complete test suite, and flake evaluation**

Run:

```bash
nix fmt
for test_file in tests/*.sh; do bash "$test_file"; done
nix flake check --no-build
git diff --check
```

Expected: every command exits 0; all repository tests and flake checks pass.

- [ ] **Step 7: Build the complete NixOS system without applying it**

Run: `nix build --no-link .#nixosConfigurations.pc.config.system.build.toplevel`

Expected: exit status 0 and a built NixOS closure whose evaluated boot-loader ID is `limine`.

- [ ] **Step 8: Commit the declarative migration**

```bash
git add modules/hosts/pc/boot.nix modules/hosts/pc/configuration.nix modules/hosts/pc/maintenance.nix tests/boot.sh tests/maintenance.sh
git commit -m "feat: migrate pc bootloader to Limine"
```

### Task 2: Install and Validate Limine Without Rebooting

**Files:**
- No repository files change.

**Interfaces:**
- Consumes: the verified `pcBoot` module and built NixOS closure from Task 1.
- Produces: an active NixOS generation with Limine installed, plus runtime evidence that the old systemd-boot fallback remains usable from the firmware menu.

- [ ] **Step 1: Capture the pre-switch recovery state**

Run a read-only privileged check using PolicyKit and save its output outside the repository or in the plan's ignored execution workspace:

```bash
pkexec sh -c '
  test -f /boot/EFI/systemd/systemd-bootx64.efi
  test -f /boot/loader/loader.conf
  efibootmgr -v
'
```

Expected: both files exist and `efibootmgr` lists an active `Linux Boot Manager` entry. Record that entry's four-digit ID.

- [ ] **Step 2: Apply the already-built Limine generation**

Run:

```bash
pkexec /run/current-system/sw/bin/nixos-rebuild switch \
  --flake /home/itterum/nixos-config/.worktrees/kde-migration#pc
```

Expected: exit status 0, with the new NixOS system path printed. Do not reboot.

- [ ] **Step 3: Verify Limine and the fallback on the ESP**

Run:

```bash
pkexec sh -c '
  test -f /boot/EFI/limine/BOOTX64.EFI
  test -f /boot/limine/limine.conf
  test -f /boot/EFI/systemd/systemd-bootx64.efi
  test -f /boot/loader/loader.conf
  grep -q "NixOS default profile" /boot/limine/limine.conf
  efibootmgr -v
'
```

Expected: all four files exist; `limine.conf` contains NixOS entries; `efibootmgr` lists active `Limine` and the previously recorded `Linux Boot Manager` entry; the first ID in `BootOrder` is the Limine entry.

- [ ] **Step 4: Verify the active system without rebooting**

Run:

```bash
test "$(nix eval --raw .#nixosConfigurations.pc.config.system.boot.loader.id)" = limine
test "$(systemctl is-system-running)" = running
systemctl is-active home-manager-itterum.service
systemctl is-active display-manager.service
```

Expected: the evaluated loader ID is `limine`; the system is running; Home Manager and the display manager are active.

- [ ] **Step 5: Run the final repository verification**

Run:

```bash
for test_file in tests/*.sh; do bash "$test_file"; done
nix flake check --no-build
git status --short --branch
```

Expected: tests and flake checks pass; the worktree is clean and the branch is ahead only by the Stage 1 and design/plan commits.

- [ ] **Step 6: Push Stage 1 and stop before reboot**

Run: `git push origin codex/kde-migration`

Expected: local `HEAD` equals `@{upstream}`. Report the preserved fallback entry and ask the user to reboot manually. Do not begin Stage 2 until the user confirms that NixOS booted through Limine.
