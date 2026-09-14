# Nix Daemon Repair Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore reliable systemd socket activation for the existing official multi-user Nix installation on the current Omarchy host.

**Architecture:** Keep the existing Nix store, profile, build users, and shell initialization. Register the service, socket, and tmpfiles definitions already shipped by `/nix/var/nix/profiles/default`, then verify both activation and store operations.

**Tech Stack:** Nix 2.35.2, systemd, systemd-tmpfiles, Omarchy/Arch Linux

**Spec:** `docs/superpowers/specs/2026-09-14-niri-desktop-restoration-design.md`

## Global Constraints

- Do not reinstall Nix or delete anything under `/nix`.
- Do not modify files inside the Nix store or active Nix profile.
- Use a graphical `pkexec` prompt because the agent cannot accept a terminal sudo password.
- Re-check every source and destination immediately before privileged changes.
- Do not commit or push repository changes.

---

### Task 1: Confirm the broken service boundary

**Files:**
- Read: `/nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.service`
- Read: `/nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.socket`
- Read: `/nix/var/nix/profiles/default/lib/tmpfiles.d/nix-daemon.conf`
- Inspect: `/etc/systemd/system/`
- Inspect: `/etc/tmpfiles.d/`

**Interfaces:**
- Consumes: active default Nix profile and the current systemd manager
- Produces: a verified set of three source paths and confirmation that their system registrations are absent

- [ ] **Step 1: Capture the pre-repair state**

```bash
systemctl is-enabled nix-daemon.service nix-daemon.socket || true
systemctl is-active nix-daemon.service nix-daemon.socket || true
nix store info --json || true
```

Expected: both units report `not-found` or inactive and the store query reports connection refused at `/nix/var/nix/daemon-socket/socket`.

- [ ] **Step 2: Validate the supplied definitions**

```bash
test -f /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.service
test -f /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.socket
test -f /nix/var/nix/profiles/default/lib/tmpfiles.d/nix-daemon.conf
systemd-analyze verify \
  /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.service \
  /nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.socket
```

Expected: all three files exist and `systemd-analyze verify` exits successfully.

- [ ] **Step 3: Confirm destinations remain absent**

```bash
test ! -e /etc/systemd/system/nix-daemon.service
test ! -e /etc/systemd/system/nix-daemon.socket
test ! -e /etc/tmpfiles.d/nix-daemon.conf
```

Expected: all checks succeed. If a destination exists, stop and inspect it rather than replacing it.

### Task 2: Register and start socket activation

**Files:**
- Create symlink: `/etc/systemd/system/nix-daemon.service`
- Create symlink: `/etc/systemd/system/nix-daemon.socket`
- Create symlink: `/etc/tmpfiles.d/nix-daemon.conf`

**Interfaces:**
- Consumes: validated paths from Task 1
- Produces: enabled `nix-daemon.socket` and on-demand `nix-daemon.service`

- [ ] **Step 1: Apply the minimal privileged repair**

```bash
pkexec /usr/bin/bash -c '
set -euo pipefail
service_source=/nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.service
socket_source=/nix/var/nix/profiles/default/lib/systemd/system/nix-daemon.socket
tmpfiles_source=/nix/var/nix/profiles/default/lib/tmpfiles.d/nix-daemon.conf

test -f "$service_source"
test -f "$socket_source"
test -f "$tmpfiles_source"
test ! -e /etc/systemd/system/nix-daemon.service
test ! -e /etc/systemd/system/nix-daemon.socket
test ! -e /etc/tmpfiles.d/nix-daemon.conf

ln -s "$service_source" /etc/systemd/system/nix-daemon.service
ln -s "$socket_source" /etc/systemd/system/nix-daemon.socket
ln -s "$tmpfiles_source" /etc/tmpfiles.d/nix-daemon.conf
systemd-tmpfiles --create --prefix=/nix/var/nix
systemctl daemon-reload
systemctl enable --now nix-daemon.socket
'
```

Expected: the desktop shows one authentication prompt and systemd enables the socket without errors.

- [ ] **Step 2: Verify socket state before using Nix**

```bash
systemctl is-enabled nix-daemon.socket
systemctl is-active nix-daemon.socket
systemctl status nix-daemon.socket --no-pager -l
```

Expected: `enabled`, `active`, and a listening socket at `/nix/var/nix/daemon-socket/socket`.

- [ ] **Step 3: Trigger the daemon through the socket**

```bash
nix store info --json
systemctl is-active nix-daemon.service
nix config check
```

Expected: store information is returned, the service becomes active, and configuration checks contain no socket failure.

### Task 3: Verify persistence and retain recovery commands

**Files:**
- Inspect: `/etc/systemd/system/nix-daemon.service`
- Inspect: `/etc/systemd/system/nix-daemon.socket`
- Inspect: `/etc/tmpfiles.d/nix-daemon.conf`

**Interfaces:**
- Consumes: repaired integration from Task 2
- Produces: reload verification and an exact non-executed rollback procedure

- [ ] **Step 1: Verify targets and enabled state**

```bash
readlink -f /etc/systemd/system/nix-daemon.service
readlink -f /etc/systemd/system/nix-daemon.socket
readlink -f /etc/tmpfiles.d/nix-daemon.conf
systemctl is-enabled nix-daemon.socket
```

Expected: all paths resolve into `/nix/var/nix/profiles/default/` and the socket remains enabled.

- [ ] **Step 2: Reload and re-test**

```bash
pkexec systemctl daemon-reload
nix store info --json
journalctl -u nix-daemon.socket -u nix-daemon.service --since '10 minutes ago' --no-pager
```

Expected: the query succeeds and the journal has no failed unit or daemon crash.

- [ ] **Step 3: Keep rollback as documentation only**

```bash
pkexec /usr/bin/bash -c '
set -euo pipefail
systemctl disable --now nix-daemon.socket
rm /etc/systemd/system/nix-daemon.service
rm /etc/systemd/system/nix-daemon.socket
rm /etc/tmpfiles.d/nix-daemon.conf
systemctl daemon-reload
'
```

Expected: do not execute this block unless the user later asks to revert the repair.
