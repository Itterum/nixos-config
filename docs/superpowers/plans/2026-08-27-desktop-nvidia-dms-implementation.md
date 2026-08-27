# Desktop NVIDIA and DMS Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a separately buildable NVIDIA RTX 5060 desktop host, keep NVIDIA out of the laptop, and deploy the current DMS settings as a mutable Home Manager-managed copy.

**Architecture:** `flake.nix` exposes two hosts through one `mkSystem` helper. Shared boot and application modules remain common; laptop power settings and hostnames live in host modules, while one focused NVIDIA module is imported only by `desktop`. DMS has a checked-in source file and an activation-time mutable copy.

**Tech Stack:** NixOS 26.05, Nix flakes, Home Manager 26.05, Limine, Niri, DankMaterialShell, NVIDIA open kernel modules 595.71.05.

**Spec:** `docs/superpowers/specs/2026-08-27-desktop-nvidia-dms-design.md`

## Global Constraints

- Keep the shared Limine and Windows 11 firmware entry on both hosts.
- Preserve laptop hostname `nixos` and its existing TLP behaviour.
- Import NVIDIA only from `hosts/desktop/default.nix`.
- Configure RTX 5060 as a non-hybrid GPU with the open NVIDIA kernel module.
- Do not invent desktop disk UUIDs or CPU-specific hardware settings.
- Preserve the user's existing unstaged `telegram-desktop` addition.
- Do not activate or switch either NixOS system automatically.

---

### Task 1: Add configuration regression test

**Files:**
- Create: `tests/configuration.sh`

**Interfaces:**
- Consumes: flake outputs `nixosConfigurations.laptop` and `nixosConfigurations.desktop`, plus the checked-in DMS JSON.
- Produces: one executable regression check for host separation, NVIDIA options and DMS values.

- [ ] **Step 1: Write the failing test**

Create a Bash script which runs `nix eval` assertions for both configurations
and Nix JSON assertions for `cornerRadius = 4`, `niriLayoutGapsOverride = 8`,
`monoFontFamily = "FiraCode Nerd Font Mono"` and the enabled workspace switcher
object.

- [ ] **Step 2: Run the test to verify RED**

Run: `bash tests/configuration.sh`

Expected: FAIL because `nixosConfigurations.desktop` does not exist.

### Task 2: Split host-specific power and add desktop NVIDIA host

**Files:**
- Modify: `flake.nix`
- Modify: `modules/system/base.nix`
- Modify: `hosts/laptop/default.nix`
- Create: `hosts/desktop/default.nix`
- Create: `hosts/desktop/hardware-configuration.nix`
- Create: `modules/hardware/nvidia.nix`
- Create: `modules/profiles/workstation.nix`

**Interfaces:**
- Consumes: all existing shared NixOS modules and Home Manager user module.
- Produces: buildable `nixosConfigurations.laptop` and `nixosConfigurations.desktop`; only the latter uses NVIDIA.

- [ ] **Step 1: Introduce a shared `mkSystem` helper**

Have `flake.nix` instantiate both host directories with the same Home Manager
integration.

- [ ] **Step 2: Move host-specific settings**

Remove hostname and laptop power settings from `base.nix`; set hostname `nixos`,
TLP enabled and power-profiles-daemon disabled in the laptop host.

Consolidate the shared module imports in `modules/profiles/workstation.nix` so
the two host compositions cannot drift.

- [ ] **Step 3: Add desktop composition and bootstrap hardware scan**

Import the same shared modules as the laptop plus `modules/hardware/nvidia.nix`,
set hostname `desktop`, and use a hardware module containing
`not-detected.nix`, `x86_64-linux` and an intentionally nonexistent sentinel
root-device label. Emit an evaluation warning and document that the file must
be replaced from the target PC before installation.

- [ ] **Step 4: Add the focused NVIDIA module**

Set `services.xserver.videoDrivers = [ "nvidia" ]`, enable
`hardware.graphics`, `hardware.nvidia.modesetting`, the open kernel module and
the stable driver package. Do not add PRIME.

- [ ] **Step 5: Run the regression test**

Run: `bash tests/configuration.sh`

Expected: host and NVIDIA assertions pass; DMS assertions still fail because
the repository snapshot has not yet been synchronized.

### Task 3: Synchronize and deploy mutable DMS settings

**Files:**
- Modify: `home/itterum/files/dms/settings.json`
- Modify: `home/itterum/desktop.nix`

**Interfaces:**
- Consumes: the current live DMS JSON in `/home/itterum/.config/DankMaterialShell/settings.json`.
- Produces: repository source matching the live settings and activation script `installDmsSettings`.

- [ ] **Step 1: Apply the four live DMS differences**

Set radius to 4, Niri gaps override to 8, monospace font to FiraCode Nerd Font
Mono and use the enabled workspace switcher object.

- [ ] **Step 2: Add mutable-copy activation**

Create the DMS config directory and install the source JSON with mode 0644
after Home Manager's write boundary.

- [ ] **Step 3: Run the regression test to verify GREEN**

Run: `bash tests/configuration.sh`

Expected: PASS.

### Task 4: Document installation and run integration verification

**Files:**
- Create: `README.md`

**Interfaces:**
- Consumes: desktop host output and bootstrap hardware module.
- Produces: exact safe steps for replacing the scan and installing `.#desktop`.

- [ ] **Step 1: Document desktop preparation**

Explain filesystem mounting, temporary hardware generation, replacement of
`hosts/desktop/hardware-configuration.nix`, and `nixos-install --flake .#desktop`.

- [ ] **Step 2: Run static and build checks**

Run:

```bash
bash tests/configuration.sh
nix flake check --no-build
nix build --no-link .#nixosConfigurations.laptop.config.system.build.toplevel
nix build --no-link .#nixosConfigurations.desktop.config.system.build.toplevel
```

Expected: all commands exit 0. Any warning caused only by the intentionally
minimal bootstrap hardware scan must be explained; option warnings must be
empty.

- [ ] **Step 3: Review the final diff**

Confirm the pre-existing Telegram line remains present and no unrelated file
or option changed.
