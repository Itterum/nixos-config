# Secure Boot Enrollment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Manually enroll the existing sbctl keys into the Gigabyte B550M DS3H firmware, enable Secure Boot, and verify NixOS through Limine plus Windows Boot Manager.

**Architecture:** This is an operational migration with no Nix configuration changes. Each firmware mutation is separated by a manual reboot checkpoint and a machine-readable state gate; enrollment preserves the original firmware/Microsoft certificates and is followed by independent NixOS and Windows boot validation.

**Tech Stack:** Gigabyte UEFI F14, Limine 12.5.2, sbctl 0.18, efibootmgr, OpenSSL, Bash, jq

**Spec:** `docs/superpowers/specs/2026-10-10-secure-boot-enrollment-design.md`

## Global Constraints

- Never enable automatic enrollment; `boot.loader.limine.secureBoot.autoEnrollKeys.enable` remains `false`.
- Never place private keys, decrypted key material, firmware-variable dumps, or runtime evidence in Git.
- Do not reboot automatically; the user performs every reboot and confirms the result.
- Do not run enrollment unless `sbctl status --json` reports `setup_mode: true` and `secure_boot: false`.
- Run `sbctl enroll-keys --microsoft --firmware-builtin` exactly once; never add `--yes-this-might-brick-my-machine`, `--ignore-immutable`, or `--partial`.
- Do not restore factory keys, clear every Secure Boot variable, or remove the systemd-boot fallback.
- Windows BitLocker is disabled.

## Review Focus

- Wrong firmware state: the Setup Mode task must assert `setup_mode: true` and `secure_boot: false` before enrollment is permitted.
- Lost vendor or Windows trust: post-enrollment checks must prove all preflight KEK/db certificates remain and Microsoft certificates are present.
- Wrong Platform Key: post-enrollment checks must prove the enrolled PK fingerprint equals `/var/lib/sbctl/keys/PK/PK.pem`.
- Unbootable NixOS: the Secure Boot task must prove Limine is the current loader, its EFI binary is signed, and the system is healthy with `secure_boot: true`.
- Incomplete compatibility validation: the final task must require a successful Windows boot and a return to NixOS with Secure Boot still enabled.

---

### Task 1: Capture Preflight State and Push Documentation

**Files:**
- No production files change.
- Create outside Git: `.superpowers/sdd/2026-10-10-secure-boot-enrollment/preflight-*`

**Interfaces:**
- Consumes: the signed Stage 2 Limine installation, sbctl key store, Kingston backup, and firmware entries.
- Produces: a preflight snapshot of firmware certificates and boot state used by Tasks 3–5.

- [ ] **Step 1: Verify the declarative enrollment boundary**

Run:

```bash
set -euo pipefail
test "$(nix eval --json .#nixosConfigurations.pc.config.boot.loader.limine.secureBoot.enable)" = true
test "$(nix eval --json .#nixosConfigurations.pc.config.boot.loader.limine.secureBoot.autoGenerateKeys)" = true
test "$(nix eval --json .#nixosConfigurations.pc.config.boot.loader.limine.secureBoot.autoEnrollKeys.enable)" = false
bash tests/boot.sh
```

Expected: all assertions pass and the test prints `Limine boot configuration assertions passed`.

- [ ] **Step 2: Capture Secure Boot and signed-loader state**

Create the ignored execution workspace, then run:

```bash
set -euo pipefail
workspace=.superpowers/sdd/2026-10-10-secure-boot-enrollment
mkdir -p "$workspace"
sbctl status --json | tee "$workspace/preflight-status.json"
pkexec sbctl verify --json | tee "$workspace/preflight-verify.json"
jq -e '.installed == true and .setup_mode == false and .secure_boot == false' \
  "$workspace/preflight-status.json" >/dev/null
jq -e 'any(.[]; (.file_name | ascii_downcase | endswith("/efi/limine/bootx64.efi")) and (.is_signed == 1))' \
  "$workspace/preflight-verify.json" >/dev/null
```

Expected: sbctl keys are installed, Setup Mode and Secure Boot are disabled, and Limine is signed.

- [ ] **Step 3: Verify the backup and record the current firmware certificates**

Run:

```bash
set -euo pipefail
workspace=.superpowers/sdd/2026-10-10-secure-boot-enrollment
sha256sum --check /mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age.sha256
sbctl list-enrolled-keys --json > "$workspace/preflight-enrolled-keys.json"
jq -e '(.PK | length) > 0 and (.KEK | length) > 0 and (.DB | length) > 0' \
  "$workspace/preflight-enrolled-keys.json" >/dev/null
```

Expected: checksum validation prints `OK`; the snapshot contains non-empty PK, KEK, and DB arrays. The snapshot contains only public certificates but remains outside Git because it is runtime evidence.

- [ ] **Step 4: Verify and record firmware boot entries**

Run:

```bash
set -euo pipefail
workspace=.superpowers/sdd/2026-10-10-secure-boot-enrollment
efi_bin=$(nix eval --raw --impure --expr '
  let pc = (builtins.getFlake "path:'"$PWD"'").nixosConfigurations.pc;
  in pc.pkgs.lib.getExe pc.pkgs.efibootmgr
')
pkexec "$efi_bin" -v | tee "$workspace/preflight-efi.txt"
grep -q '^Boot0004\* Limine' "$workspace/preflight-efi.txt"
grep -q '^Boot0002\* Linux Boot Manager' "$workspace/preflight-efi.txt"
grep -q '^Boot0000\* Windows Boot Manager' "$workspace/preflight-efi.txt"
grep -q '^BootOrder: 0004,' "$workspace/preflight-efi.txt"
```

Expected: all three firmware entries exist and Limine remains first in BootOrder.

- [ ] **Step 5: Push the approved design and plan before firmware work**

Run:

```bash
git push origin codex/kde-migration
test "$(git rev-parse HEAD)" = "$(git rev-parse '@{upstream}')"
git status --short --branch
```

Expected: local HEAD equals upstream and the tracked worktree is clean.

### Task 2: Enter Firmware Setup Mode

**Files:**
- No repository files change.

**Interfaces:**
- Consumes: the successful Task 1 preflight and the Gigabyte firmware's Secure Boot controls.
- Produces: firmware Setup Mode with Secure Boot still disabled, which is the hard gate for Task 3.

- [ ] **Step 1: Stop before the destructive firmware action**

Report the verified recovery paths and ask the user to reboot manually into Gigabyte UEFI by pressing `Delete` during startup. Do not initiate the reboot.

Expected: the user explicitly confirms they are ready to change only the Platform Key state.

- [ ] **Step 2: Place the firmware in Setup Mode**

In the Gigabyte UEFI Secure Boot page:

1. Keep Secure Boot disabled.
2. Select Custom mode if required to expose key controls.
3. Use the control explicitly named `Reset To Setup Mode`, `Delete Platform Key`, or its exact firmware equivalent that removes only PK.
4. Do not select `Restore Factory Keys`, `Install Default Keys`, or a command that deletes every Secure Boot variable.
5. Save changes and reboot NixOS manually through Limine.

If the firmware offers only an ambiguous all-keys deletion action, cancel without saving and report the exact labels shown.

- [ ] **Step 3: Prove Setup Mode after NixOS boots**

Run:

```bash
set -euo pipefail
workspace=.superpowers/sdd/2026-10-10-secure-boot-enrollment
sbctl status --json | tee "$workspace/setup-mode-status.json"
jq -e '.installed == true and .setup_mode == true and .secure_boot == false' \
  "$workspace/setup-mode-status.json" >/dev/null
bootctl status | grep -q 'Product: Limine'
```

Expected: Setup Mode is true, Secure Boot is false, and the current loader is Limine. If any assertion fails, stop without enrolling.

### Task 3: Enroll sbctl, Microsoft, and Firmware-Builtin Keys

**Files:**
- No repository files change.
- Create outside Git: `.superpowers/sdd/2026-10-10-secure-boot-enrollment/post-enrollment-*`

**Interfaces:**
- Consumes: verified Setup Mode from Task 2 and the preflight certificate snapshot from Task 1.
- Produces: the local sbctl PK enrolled in firmware with the pre-existing KEK/db certificate set preserved and Secure Boot still disabled.

- [ ] **Step 1: Re-run the immediate enrollment gate**

Run immediately before enrollment:

```bash
set -euo pipefail
status=$(sbctl status --json)
jq -e '.installed == true and .setup_mode == true and .secure_boot == false' <<<"$status" >/dev/null
sha256sum --check /mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age.sha256
```

Expected: the status assertion passes and the backup checksum prints `OK`. Otherwise stop.

- [ ] **Step 2: Obtain explicit confirmation and enroll exactly once**

Show the exact command to the user and obtain explicit confirmation immediately before executing it:

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

Run it once in an interactive Foot terminal. Do not add other flags and do not retry automatically.

Expected: sbctl reports successful enrollment of PK, KEK, and db. Any error stops the plan before another firmware change or retry.

- [ ] **Step 3: Verify post-enrollment state and capture public certificates**

Run:

```bash
set -euo pipefail
workspace=.superpowers/sdd/2026-10-10-secure-boot-enrollment
sbctl status --json | tee "$workspace/post-enrollment-status.json"
sbctl list-enrolled-keys --json > "$workspace/post-enrollment-keys.json"
jq -e '.installed == true and .setup_mode == false and .secure_boot == false' \
  "$workspace/post-enrollment-status.json" >/dev/null
jq -e --slurpfile after "$workspace/post-enrollment-keys.json" '
  (([.KEK[], .DB[]] | map(.Raw)) -
   ([$after[0].KEK[], $after[0].DB[]] | map(.Raw)) | length) == 0
' "$workspace/preflight-enrolled-keys.json" >/dev/null
jq -e '.. | objects | select(.Subject?.Organization? | arrays and index("Microsoft Corporation"))' \
  "$workspace/post-enrollment-keys.json" >/dev/null
```

Expected: Setup Mode is false while Secure Boot remains disabled; every preflight KEK/db certificate remains enrolled; at least one Microsoft certificate is present.

- [ ] **Step 4: Prove the enrolled Platform Key matches the local sbctl certificate**

Run:

```bash
set -euo pipefail
workspace=.superpowers/sdd/2026-10-10-secure-boot-enrollment
openssl_bin=$(nix eval --raw --impure --expr '
  let pc = (builtins.getFlake "path:'"$PWD"'").nixosConfigurations.pc;
  in pc.pkgs.lib.getExe pc.pkgs.openssl
')
enrolled_pk=$(
  jq -r '.PK[0].Raw' "$workspace/post-enrollment-keys.json" |
    base64 -d |
    "$openssl_bin" x509 -inform DER -outform DER |
    sha256sum | cut -d' ' -f1
)
local_pk=$(
  pkexec sh -ec '"$1" x509 -in /var/lib/sbctl/keys/PK/PK.pem -outform DER' sh "$openssl_bin" |
    sha256sum | cut -d' ' -f1
)
test "$enrolled_pk" = "$local_pk"
```

Expected: both SHA-256 fingerprints are identical. Do not print or read any private key.

### Task 4: Enable Secure Boot and Validate NixOS

**Files:**
- No repository files change.

**Interfaces:**
- Consumes: verified custom enrollment from Task 3.
- Produces: a successful NixOS boot through signed Limine with firmware Secure Boot enabled.

- [ ] **Step 1: Stop before enabling Secure Boot**

Report the matching PK fingerprint, preserved KEK/db set, Microsoft certificate presence, and disabled Secure Boot state. Ask the user to reboot manually into UEFI.

Expected: the user explicitly confirms they are ready to enable Secure Boot.

- [ ] **Step 2: Enable Secure Boot without replacing keys**

In Gigabyte UEFI, enable Secure Boot while retaining the enrolled Custom key set. Do not restore factory/default keys. Save and boot the existing Limine entry manually.

If NixOS does not boot, disable Secure Boot in firmware and boot Limine; do not change or delete keys.

- [ ] **Step 3: Verify the Secure Boot NixOS session**

Run:

```bash
set -euo pipefail
workspace=.superpowers/sdd/2026-10-10-secure-boot-enrollment
sbctl status --json | tee "$workspace/secure-boot-status.json"
pkexec sbctl verify --json | tee "$workspace/secure-boot-verify.json"
jq -e '.installed == true and .setup_mode == false and .secure_boot == true' \
  "$workspace/secure-boot-status.json" >/dev/null
jq -e 'any(.[]; (.file_name | ascii_downcase | endswith("/efi/limine/bootx64.efi")) and (.is_signed == 1))' \
  "$workspace/secure-boot-verify.json" >/dev/null
bootctl status | grep -q 'Product: Limine'
test "$(systemctl is-system-running)" = running
systemctl is-active display-manager.service
systemctl is-active home-manager-itterum.service
sha256sum --check /mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age.sha256
```

Expected: Secure Boot is enabled outside Setup Mode; Limine is current and signed; the system and desktop services are healthy; the backup checksum prints `OK`.

### Task 5: Verify Windows and Return to NixOS

**Files:**
- No repository files change.

**Interfaces:**
- Consumes: the verified Secure Boot NixOS state from Task 4 and the preserved Windows Boot Manager entry.
- Produces: end-to-end evidence that both operating systems boot under the enrolled trust set.

- [ ] **Step 1: Ask the user to test Windows manually**

Ask the user to reboot and select `Windows Boot Manager` from the firmware boot menu. Do not change BootOrder and do not initiate the reboot.

Expected: Windows reaches the normal desktop without a BitLocker recovery prompt.

- [ ] **Step 2: Return to NixOS through Limine**

Ask the user to reboot and select the normal Limine entry, then report that NixOS has loaded.

- [ ] **Step 3: Run the final cross-boot verification**

Run:

```bash
set -euo pipefail
status=$(sbctl status --json)
jq -e '.installed == true and .setup_mode == false and .secure_boot == true' <<<"$status" >/dev/null
bootctl status | grep -q 'Product: Limine'
test "$(systemctl is-system-running)" = running
sha256sum --check /mnt/storage/secure-boot-backup/pc-sbctl-keys-2026-10-10.tar.age.sha256
test "$(git rev-parse HEAD)" = "$(git rev-parse '@{upstream}')"
git status --short --branch
```

Expected: Secure Boot remains enabled after both operating-system boots; Limine is current; the system is healthy; the backup is intact; the tracked branch is clean and synchronized.

- [ ] **Step 4: Preserve recovery fallback for a later cleanup**

Report completion but leave the old systemd-boot files and firmware entry unchanged. Their removal requires a later, separately approved cleanup after the user has used both NixOS and Windows normally under Secure Boot.
