# Secure Boot Enrollment Design

## Goal

Enroll the existing sbctl keys into the `pc` host firmware, enable Secure Boot, and verify both signed Limine and Windows Boot Manager without weakening the recovery path established during the Limine migration.

## Starting State

- The host is a Gigabyte B550M DS3H running firmware F14.
- NixOS boots through Limine 12.5.2 from firmware entry `0004`.
- Limine Secure Boot signing is enabled declaratively and `/boot/EFI/limine/BOOTX64.EFI` is signed.
- sbctl keys exist under root-owned `/var/lib/sbctl`.
- The encrypted key backup and its SHA-256 checksum exist on the Kingston filesystem with UUID `BFB4-A380`.
- Secure Boot and firmware Setup Mode are both currently disabled.
- Windows BitLocker is not enabled.
- The existing `Linux Boot Manager` and Windows firmware entries remain available.

## Safety Boundary

Firmware enrollment is manual and occurs only after the machine reports Setup Mode. NixOS automatic enrollment remains disabled. Private keys stay under `/var/lib/sbctl` and in the encrypted Kingston backup; they never enter Git or the Nix store.

No command may clear firmware keys, restore factory defaults, enroll keys, or enable Secure Boot without a checkpoint immediately before that action. No reboot is initiated automatically.

## Enrollment Flow

### Preflight

Before entering firmware settings:

- verify the active boot loader is Limine;
- verify sbctl reports installed keys and Secure Boot disabled;
- verify Limine is signed;
- validate the encrypted backup checksum;
- confirm the Limine, systemd-boot, and Windows firmware entries still exist;
- record the current boot order.

Any failed preflight check stops the procedure.

### Enter Setup Mode

The user reboots into the Gigabyte firmware UI manually. Secure Boot is placed in Custom/Setup Mode by clearing only the Platform Key through the firmware's Setup Mode control. Secure Boot remains disabled. Factory keys are not restored and all firmware keys are not indiscriminately cleared.

After booting NixOS again, `sbctl status --json` must report `setup_mode: true` and `secure_boot: false`. If it does not, no enrollment command is run.

### Enroll Keys

Run exactly one manual enrollment command:

```bash
sudo sbctl enroll-keys --microsoft --firmware-builtin
```

The Microsoft keys preserve Windows compatibility. Firmware-builtin keys preserve vendor-authorized firmware utilities when the firmware exposes them. After enrollment, sbctl must report that Setup Mode is no longer active while Secure Boot remains disabled until the firmware setting is changed.

Do not use automatic enrollment and do not run a second enrollment attempt without first diagnosing the recorded result.

Enrollment replaces the previous generic Platform Key, Key Exchange Key, and Database Key certificates with the local sbctl PK, KEK, and db certificates. The preflight fingerprints identify those three retired certificates exactly; every other preflight KEK and db certificate must remain in its original variable. The new PK, KEK, and db fingerprints must match their local sbctl public certificates.

Gigabyte F14 may keep reporting Setup Mode until the next firmware boot cycle after accepting the new PK. If that occurs, reboot once with Secure Boot still disabled, make no additional key changes, and require `setup_mode: false` before proceeding. Never repeat enrollment merely because Setup Mode has not refreshed before that reboot.

### Enable Secure Boot

The user reboots into firmware settings manually and enables Secure Boot without restoring factory keys. The user then boots NixOS through the existing Limine entry.

Post-boot validation requires:

- Limine is the current boot loader;
- `sbctl status --json` reports `secure_boot: true`;
- `/boot/EFI/limine/BOOTX64.EFI` remains signed;
- the system, display manager, and Home Manager services are healthy;
- the encrypted backup checksum remains valid.

Finally, the user boots Windows through its existing Windows Boot Manager entry. With BitLocker disabled and Microsoft keys enrolled, Windows should boot normally. The user returns to NixOS and confirms Secure Boot remains enabled.

## Recovery

If NixOS fails to boot after enabling Secure Boot, disable Secure Boot in firmware and boot Limine again. The preserved systemd-boot entry remains a fallback only while Secure Boot is disabled because its EFI binary is not signed with the enrolled custom key.

If enrollment is rejected or firmware state is unexpected, do not retry blindly. Leave Secure Boot disabled, return firmware to Setup Mode if necessary, and inspect `sbctl status` before choosing a recovery action. The encrypted Kingston backup is the recovery source for the custom keys.

If Windows fails to boot, disable Secure Boot and use the existing Windows Boot Manager entry. Do not restore factory keys or delete the custom keys until the failure has been diagnosed.

## Repository Scope

No Nix configuration change is required for enrollment. The existing declarative settings remain:

- Limine Secure Boot signing enabled;
- missing-key generation enabled;
- automatic firmware enrollment disabled;
- `sbctl` and `age` installed.

Only this design and its execution plan are committed. Firmware state, private keys, decrypted key material, and runtime evidence stay outside Git.
