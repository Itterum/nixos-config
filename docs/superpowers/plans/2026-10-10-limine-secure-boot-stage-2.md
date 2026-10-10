# Limine Secure Boot Stage 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prepare the `pc` host for Secure Boot by generating local signing keys, signing Limine, and creating a verified encrypted key backup on the Kingston disk, while leaving firmware enrollment and Secure Boot disabled.

**Architecture:** The existing host-specific `pcBoot` module remains the single owner of boot and signing policy. Evaluation tests pin signing, key generation, tooling, and the disabled enrollment boundary; runtime checks prove that keys were generated and Limine was signed before an interactive `age` backup is written to the declaratively mounted Kingston disk.

**Tech Stack:** NixOS 26.05 modules, Limine, sbctl 0.18, age, UEFI, Bash, jq

**Spec:** `docs/superpowers/specs/2026-10-10-limine-secure-boot-design.md`

## Global Constraints

- Stage 2 preparation only: do not enroll keys into firmware and do not enable Secure Boot in firmware.
- Keep `boot.loader.limine.secureBoot.autoEnrollKeys.enable = false`.
- Generate keys only as root-owned runtime state under `/var/lib/sbctl`; never reference or copy private keys into Git or the Nix store.
- Preserve the Limine firmware entry and the existing `Linux Boot Manager` systemd-boot fallback.
- Keep Microsoft and firmware-vendor keys for the later, separately approved manual enrollment stage.
- Do not reboot the machine automatically.
- Write the encrypted backup only to `/mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age`; the user enters its passphrase interactively and it must never appear in configuration, Git, logs, or shell arguments.

## Review Focus

- Premature firmware mutation: the evaluation test must prove automatic enrollment remains disabled, and runtime work must not invoke `sbctl enroll-keys`.
- Unsigned boot path: runtime verification must prove `/boot/EFI/limine/BOOTX64.EFI` is signed after the switch and before any firmware work.
- Missing or misplaced private keys: runtime verification must prove sbctl owns a generated key hierarchy under `/var/lib/sbctl`, while a repository scan proves no key material entered the worktree.
- Unrecoverable key loss: backup verification must decrypt the archive, list the expected sbctl key hierarchy, and validate a sidecar SHA-256 checksum before the reboot checkpoint.
- Broken recovery path: runtime verification must prove the Limine and preserved systemd-boot EFI files and firmware entries still coexist after signing.

---

### Task 1: Declarative Secure Boot Signing Preparation

**Files:**
- Modify: `tests/boot.sh`
- Modify: `modules/hosts/pc/boot.nix`

**Interfaces:**
- Consumes: the Stage 1 `flake.nixosModules.pcBoot` module and `flake.nixosConfigurations.pc.config`.
- Produces: a `pc` configuration with Limine signing and missing-key generation enabled, automatic enrollment disabled, and `sbctl` plus `age` available system-wide.

- [ ] **Step 1: Extend the boot evaluation test and make it fail**

Update `tests/boot.sh` so its evaluated JSON also reports whether `pc.pkgs.sbctl` and `pc.pkgs.age` occur in `config.environment.systemPackages`. Change the Secure Boot assertions to require:

- `boot.loader.limine.secureBoot.enable == true`;
- `boot.loader.limine.secureBoot.autoGenerateKeys == true`;
- `boot.loader.limine.secureBoot.autoEnrollKeys.enable == false`;
- both `sbctl` and `age` are installed system packages;
- every existing Stage 1 loader, UEFI, editor, and generation-limit assertion remains unchanged.

Run: `bash tests/boot.sh`

Expected: exit status 1 because signing, automatic key generation, and the two packages are not enabled yet.

- [ ] **Step 2: Enable signing and add the required tools**

Change `modules/hosts/pc/boot.nix` to accept `pkgs`, add `pkgs.sbctl` and `pkgs.age` to `environment.systemPackages`, and set:

```nix
boot.loader.limine.secureBoot = {
  enable = true;
  autoGenerateKeys = true;
  autoEnrollKeys.enable = false;
};
```

Do not set or override `autoEnrollKeys.extraArgs`; the pinned NixOS default already preserves Microsoft and firmware-builtin keys for the later manual enrollment stage.

- [ ] **Step 3: Run the focused test**

Run: `bash tests/boot.sh`

Expected: exit status 0 and `Limine boot configuration assertions passed`.

- [ ] **Step 4: Run formatting, complete evaluation, and a system build**

Run:

```bash
nix fmt
for test_file in tests/*.sh; do bash "$test_file"; done
nix flake check --no-build
nix build --no-link .#nixosConfigurations.pc.config.system.build.toplevel
git diff --check
```

Expected: every command exits 0; the complete `pc` closure builds without applying it.

- [ ] **Step 5: Prove the repository contains no key material and commit**

Run:

```bash
test -z "$(find . -path ./.git -prune -o -type f \( -name '*.key' -o -name '*.pem' -o -name '*.auth' -o -name '*.esl' \) -print)"
git diff --check
git add modules/hosts/pc/boot.nix tests/boot.sh
git commit -m "feat: prepare Limine Secure Boot signing"
```

Expected: the key-material scan is empty and the commit contains only the boot module and its evaluation test.

### Task 2: Generate Keys and Sign Limine Without Firmware Enrollment

**Files:**
- No repository files change.

**Interfaces:**
- Consumes: the built configuration from Task 1 and the current unsigned Limine installation.
- Produces: root-owned sbctl keys under `/var/lib/sbctl` and a signed Limine EFI binary, with Secure Boot and automatic enrollment still disabled.

- [ ] **Step 1: Capture the pre-switch security and recovery state**

Resolve `sbctl` and `efibootmgr` from the pinned `pc` package set, then save strict read-only evidence outside tracked repository files:

```bash
set -euo pipefail
sbctl_pkg=$(nix build --no-link --print-out-paths .#nixosConfigurations.pc.pkgs.sbctl)
efi_pkg=$(nix build --no-link --print-out-paths --impure --expr '
  let pc = (builtins.getFlake "path:'"$PWD"'").nixosConfigurations.pc;
  in pc.pkgs.lib.getBin pc.pkgs.efibootmgr
')
mkdir -p .superpowers/sdd/2026-10-10-limine-secure-boot-stage-2
{
  pkexec "$sbctl_pkg/bin/sbctl" status --json
  pkexec "$efi_pkg/bin/efibootmgr" -v
  pkexec sh -ec '
    test -f /boot/EFI/limine/BOOTX64.EFI
    test -f /boot/EFI/systemd/systemd-bootx64.efi
  '
} | tee .superpowers/sdd/2026-10-10-limine-secure-boot-stage-2/pre-switch.txt
```

Expected: sbctl reports `"secure_boot": false`; `efibootmgr` lists both `Limine` and `Linux Boot Manager`; both EFI files exist. Stop if Secure Boot is already enabled or either recovery entry/file is missing.

- [ ] **Step 2: Apply the signed Limine generation**

Run:

```bash
pkexec /run/current-system/sw/bin/nixos-rebuild switch \
  --flake /home/itterum/nixos-config/.worktrees/kde-migration#pc
```

Expected: exit status 0 and a new active NixOS system path. Do not reboot.

- [ ] **Step 3: Verify generated keys, disabled Secure Boot, and the Limine signature**

Run:

```bash
set -euo pipefail
{
  pkexec sbctl status --json
  pkexec sbctl verify --json
  pkexec sh -ec '
    test -d /var/lib/sbctl/keys
    test -f /boot/EFI/limine/BOOTX64.EFI
    test -f /boot/EFI/systemd/systemd-bootx64.efi
    test -n "$(find /var/lib/sbctl/keys -type f -print -quit)"
    test -z "$(find /var/lib/sbctl/keys -type f -empty -print -quit)"
    test -z "$(find /var/lib/sbctl -not -user root -print -quit)"
  '
} | tee .superpowers/sdd/2026-10-10-limine-secure-boot-stage-2/post-switch-signing.txt
```

Expected: `sbctl status --json` reports `"installed": true` and `"secure_boot": false`; `sbctl verify --json` marks `/boot/EFI/limine/BOOTX64.EFI` as signed; the root-owned key directory contains only non-empty key files; both recovery EFI files remain present. The command history contains no `sbctl enroll-keys` invocation.

- [ ] **Step 4: Verify firmware entries and active services remain healthy**

Run:

```bash
set -euo pipefail
efi_pkg=$(nix build --no-link --print-out-paths --impure --expr '
  let pc = (builtins.getFlake "path:'"$PWD"'").nixosConfigurations.pc;
  in pc.pkgs.lib.getBin pc.pkgs.efibootmgr
')
pkexec "$efi_pkg/bin/efibootmgr" -v \
  | tee .superpowers/sdd/2026-10-10-limine-secure-boot-stage-2/post-switch-efi.txt
test "$(systemctl is-system-running)" = running
systemctl is-active home-manager-itterum.service
systemctl is-active display-manager.service
```

Expected: Limine remains first in `BootOrder`; both `Limine` and `Linux Boot Manager` entries exist; the system, Home Manager, and display manager are active.

### Task 3: Create and Verify the Encrypted Kingston Backup

**Files:**
- Create outside Git: `/mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age`
- Create outside Git: `/mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age.sha256`

**Interfaces:**
- Consumes: the generated `/var/lib/sbctl` runtime key store from Task 2 and the existing `/mnt/storage` automount for UUID `BFB4-A380`.
- Produces: a passphrase-encrypted age archive and verified checksum on the Kingston disk; the passphrase remains known only to the user.

- [ ] **Step 1: Validate the exact backup target without overwriting data**

Run in an interactive Foot terminal:

```bash
set -euo pipefail
backup=/mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age
findmnt -rn -S UUID=BFB4-A380 -T /mnt/storage
test ! -e "$backup"
test ! -e "$backup.sha256"
mkdir -p "$(dirname "$backup")"
```

Expected: `findmnt` resolves `/mnt/storage` to the ExFAT filesystem with UUID `BFB4-A380`; neither backup path exists. Stop and ask the user before choosing a different filename if either path already exists.

- [ ] **Step 2: Create the passphrase-encrypted archive**

Still in the interactive Foot terminal, run:

```bash
set -euo pipefail
backup=/mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age
pkexec tar -C /var/lib -cf - sbctl | age -p -o "$backup"
```

Expected: `age` prompts the user for a new passphrase twice and exits 0. The passphrase is not echoed, logged, supplied as an argument, or written anywhere by the implementation.

- [ ] **Step 3: Verify decryption and archive contents**

Run:

```bash
set -euo pipefail
backup=/mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age
age -d "$backup" | tar -tf - | tee /tmp/pc-sbctl-backup-contents.txt
grep -q '^sbctl/keys/' /tmp/pc-sbctl-backup-contents.txt
test "$(grep -Ec '^sbctl/keys/(PK|KEK|db)/' /tmp/pc-sbctl-backup-contents.txt)" -ge 3
```

Expected: `age` prompts for the passphrase, decryption succeeds, and the archive contains the sbctl key hierarchy for `PK`, `KEK`, and `db`. No decrypted key file is written to disk.

- [ ] **Step 4: Create and validate the checksum**

Run:

```bash
set -euo pipefail
backup=/mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age
sha256sum "$backup" > "$backup.sha256"
sha256sum --check "$backup.sha256"
sync "$backup" "$backup.sha256"
```

Expected: checksum verification prints `OK`; both non-empty files exist on the Kingston disk.

### Task 4: Final Verification, Push, and Reboot Checkpoint

**Files:**
- No repository files change.

**Interfaces:**
- Consumes: the signed system generation and verified encrypted backup from Tasks 2 and 3.
- Produces: a pushed Stage 2 preparation commit and a manual reboot checkpoint before any firmware enrollment work.

- [ ] **Step 1: Run the final repository and runtime safety checks**

Run:

```bash
set -euo pipefail
for test_file in tests/*.sh; do bash "$test_file"; done
nix flake check --no-build
test -z "$(find . -path ./.git -prune -o -type f \( -name '*.key' -o -name '*.pem' -o -name '*.auth' -o -name '*.esl' \) -print)"
pkexec sbctl status --json | tee .superpowers/sdd/2026-10-10-limine-secure-boot-stage-2/final-status.txt
pkexec sbctl verify --json | tee .superpowers/sdd/2026-10-10-limine-secure-boot-stage-2/final-verify.txt
sha256sum --check /mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age.sha256
git status --short --branch
```

Expected: tests and flake checks pass; the repository contains no key material; sbctl reports keys installed with Secure Boot disabled; Limine verifies as signed; the encrypted backup checksum is valid; only the committed Stage 2 configuration change is present.

- [ ] **Step 2: Push the preparation commit**

Run:

```bash
git push origin codex/kde-migration
test "$(git rev-parse HEAD)" = "$(git rev-parse '@{upstream}')"
```

Expected: local `HEAD` equals its upstream.

- [ ] **Step 3: Stop for the user's manual reboot confirmation**

Report that signing is active, Secure Boot remains disabled, no firmware keys were enrolled, and the encrypted backup was verified. Ask the user to reboot normally and confirm that signed Limine still boots while firmware Secure Boot remains disabled.

Do not enter firmware Setup Mode, run `sbctl enroll-keys`, enable Secure Boot, remove the systemd-boot fallback, or begin the enrollment stage until the user explicitly confirms this reboot and approves a separate enrollment plan.
