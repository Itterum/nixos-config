# Limine and Secure Boot Design

## Goal

Replace systemd-boot with Limine on the `pc` NixOS host, then prepare and enable Secure Boot without breaking the existing Windows installation. The migration must remain recoverable at every step and must not enroll firmware keys automatically.

## Current State

- The machine boots in UEFI mode from the 1 GiB FAT32 ESP mounted at `/boot`.
- systemd-boot is the active NixOS boot loader.
- Secure Boot is disabled, the firmware supports Setup Mode, and TPM 2.0 is available.
- Windows is installed on a separate NVMe disk with its own EFI System Partition.
- `sbctl` is not currently installed and no sbctl key store has been configured.
- NixOS keeps at most 10 systemd-boot entries and removes generations older than 14 days weekly.

## Safety Principles

- Separate the boot-loader migration from Secure Boot key management.
- Do not reboot the machine automatically.
- Do not enroll or replace firmware keys automatically.
- Preserve the existing systemd-boot EFI files and firmware entry during the Limine validation stage.
- Keep Microsoft and firmware-vendor keys when custom Secure Boot keys are enrolled so Windows and firmware utilities remain bootable.
- Never store private Secure Boot keys in Git or the Nix store.

## Stage 1: Migrate to Limine

### Configuration

Create a host-specific boot module and move all boot-loader settings into it. The module will:

- disable systemd-boot;
- enable Limine with UEFI support;
- keep `boot.loader.efi.canTouchEfiVariables = true`;
- disable Limine's boot-entry editor;
- retain at most 10 NixOS generations in Limine;
- leave Limine Secure Boot support disabled.

The existing systemd-boot generation limit will be removed from the maintenance module because Limine has its own `maxGenerations` option.

### Validation

An evaluation test will assert that Limine is enabled with the intended options, systemd-boot is disabled, and Secure Boot signing remains disabled. Before applying the change, the complete test suite and NixOS build must pass.

After applying the generation, verify:

- Limine files and `limine.conf` exist on the ESP;
- a Limine UEFI boot entry exists and is first in the boot order;
- the previous `Linux Boot Manager` systemd-boot entry and files still exist as a fallback;
- the active running system remains healthy.

The user will reboot manually and confirm that NixOS starts through Limine. Stage 2 must not begin before that confirmation.

## Stage 2: Prepare Secure Boot

### Key Creation and Signing

After Limine has booted successfully:

- install `sbctl` as a system package;
- enable Limine Secure Boot signing;
- allow the NixOS Limine installer to generate keys in `/var/lib/sbctl` when none exist;
- keep automatic firmware enrollment disabled;
- rebuild while firmware Secure Boot is still disabled.

The private keys remain root-owned under `/var/lib/sbctl`. They are runtime machine state and are not referenced by the repository or copied into the Nix store.

### Validation and Backup

Before firmware enrollment:

- confirm that sbctl reports generated keys;
- verify the Limine EFI binary is signed;
- verify the rebuilt boot configuration succeeds with Secure Boot still disabled;
- create an encrypted or otherwise access-controlled backup of `/var/lib/sbctl` at a user-selected destination.

No backup destination will be assumed or written without explicit user direction.

### Firmware Enrollment

Enrollment is an explicit manual operation:

1. Enter firmware settings and place Secure Boot in Setup Mode.
2. Boot NixOS with Secure Boot still disabled or in Setup Mode.
3. Run `sbctl enroll-keys --microsoft --firmware-builtin`.
4. Verify enrollment with `sbctl status`.
5. Enable Secure Boot in firmware.
6. Boot NixOS and verify that Secure Boot is enabled and Limine loads the signed configuration.
7. Verify Windows through its existing firmware boot entry.

Microsoft keys preserve Windows boot compatibility. Firmware-builtin keys preserve vendor-signed firmware utilities where supported.

## Recovery

If Limine does not boot during Stage 1, select the preserved `Linux Boot Manager` entry from the firmware boot menu and roll back the NixOS generation.

If signed Limine does not boot during Stage 2, disable Secure Boot in firmware. The machine can then use Limine or the preserved systemd-boot entry for recovery. If key enrollment is incorrect, clear custom Secure Boot keys or return the firmware to Setup Mode before trying enrollment again.

The old systemd-boot files and firmware entry are not a permanent second managed boot loader. They remain only as a migration fallback and may be removed in a later, separately approved cleanup after Limine and Secure Boot have both been validated.

## Repository Changes

- Add `modules/hosts/pc/boot.nix` for all host boot-loader settings.
- Import the new boot module from the `pc` configuration.
- Remove boot-loader settings from `configuration.nix` and the systemd-boot limit from `maintenance.nix`.
- Add an evaluation test for Stage 1 boot-loader invariants.
- Extend that test during Stage 2 to cover signing, key generation, and disabled automatic enrollment.

Each stage gets its own verified commit. Stage 1 may be pushed before reboot. Stage 2 begins only after the user confirms a successful Limine boot.
