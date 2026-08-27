# Desktop NVIDIA and DMS design

Date: 2026-08-27

## Goal

Extend the personal NixOS flake with a separately addressable `desktop` host
for an NVIDIA RTX 5060 while preserving the current `laptop` behaviour, and
make the checked-in DMS settings the declarative source used by Home Manager.

## Host boundaries

Both hosts use the same `workstation` profile, Limine configuration and Windows
firmware entry because both machines are dual-boot systems. The profile owns
the shared desktop, program, network, user, locale and boot modules.

The laptop keeps hostname `nixos`, TLP and disabled power-profiles-daemon. The
desktop uses hostname `desktop`, does not enable TLP, and imports the NVIDIA
module. The NVIDIA module is never imported by the laptop.

The desktop hardware scan cannot be derived on the laptop. The repository
therefore contains a buildable bootstrap hardware module with the platform,
`not-detected.nix` import and an intentionally nonexistent root-device label.
Before installation it must be replaced
by the output of `nixos-generate-config --root /mnt --dir <temporary-dir>` from
the target PC, so that real filesystems, initrd drivers and CPU firmware are
recorded. An explicit warning identifies the bootstrap state during evaluation.

## NVIDIA RTX 5060

The desktop selects the current stable NVIDIA package from the configured
kernel package set, enables the open kernel module, DRM modesetting and the
normal graphics stack. PRIME is omitted because the machine is not hybrid.
Laptop power-management workarounds and optional container GPU integration are
outside this change.

## DMS ownership

`home/itterum/files/dms/settings.json` is synchronized from the current live
DMS settings. Home Manager copies it to
`~/.config/DankMaterialShell/settings.json` during activation rather than
creating a Nix-store symlink. DMS can continue editing the live file; a later
Home Manager activation intentionally restores the repository version.

## Verification

A repository test asserts the two host outputs, shared Limine setup, separate
hostnames and TLP state, NVIDIA isolation and the intended DMS values. Both
NixOS toplevels must evaluate and build; the laptop must retain an empty NVIDIA
driver list while the desktop resolves the stable NVIDIA driver.
