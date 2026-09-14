# Appearance, applications, and Arc Dock verification

## Automated verification

Run from the repository root on any Linux host with flakes enabled:

```sh
bash tests/theme.sh
bash tests/applications.sh
bash tests/dock.sh
bash tests/configuration.sh
./itterum-shell/test/itterum-shell
nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'
```

`nix develop` is not required for these checks. The quoted flake reference is
important in Zsh because an unquoted `#` expression can be parsed as a glob.

The tests cover the shared Kanagawa palette, the exact application allowlist,
Bibata Modern Classic at size 24, the declarative dock plugin/configuration and
pin order, the absence of Omarchy command and web-app dependencies, the
compositor boundary, and the complete NixOS system closure.

## Theme adaptation contract

- Exact Kanagawa configuration: Itterum Shell, Hyprland decoration colors,
  Foot, Helix, Zed, and Zellij.
- Toolkit dark adaptation: Files and Disks use the GTK dark theme; Telegram
  uses the configured Qt dark style; ChatGPT/Codex, Obsidian, Bruno, Brave, and
  Google Chrome receive the system dark/toolkit environment where supported.
- Cursor: Bibata Modern Classic, size 24, is shared by Home Manager, GTK,
  dconf, X11, and the Hyprland session environment.

## Graphical acceptance test

This part must be performed in the resulting NixOS Hyprland session. It is not
considered verified by a build on the current Omarchy host.

1. Confirm the launcher contains only the approved desktop IDs and that Helix,
   Codex CLI, and Zellij open inside Foot.
2. Confirm Arc Dock starts at the bottom with 111% magnification and the pinned
   order: Foot, Files, Zed, ChatGPT, Obsidian, Brave, Google Chrome, Telegram,
   Bruno.
3. Open two windows of one application; verify click-to-focus, cycling, close,
   pin/unpin, drag reorder, recents, and persistence after restarting the shell.
4. Check `never`, `fullscreen`, `covered`, and `always` auto-hide modes; repeat
   on a second output and verify the chosen output survives restart.
5. Verify blur and Kanagawa contrast, then temporarily disable notifications
   and ensure the dock continues without badges.
6. Inspect normal, text, link, resize, busy, and XWayland cursors, and confirm
   GTK, Qt, Electron/Chromium, shell, terminal, and editor surfaces remain
   legible at the active display scale.

If the session is reachable from a TTY, useful diagnostics are:

```sh
systemctl --user status itterum-shell.service --no-pager
journalctl --user -u itterum-shell.service -b --no-pager
hyprctl configerrors
```
