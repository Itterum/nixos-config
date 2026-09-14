# Hyprland and Itterum Shell core test

## Safe host-side build

From the repository root on any Linux host with flakes enabled:

```bash
bash tests/configuration.sh
nix build --no-link 'path:.#nixosConfigurations.desktop.config.system.build.toplevel'
```

This does not switch the current host, write its bootloader, or start Hyprland and Itterum Shell. It only produces the system closure in the Nix store.

## Disposable graphical machine

Replace `hosts/desktop/hardware-configuration.nix` with the machine's generated file before installing. After boot, select `Hyprland (uwsm-managed)` in greetd. The session has recovery bindings that do not depend on the shell:

- `Super+Return`: open Foot.
- `Super+Shift+R`: restart Itterum Shell.
- `Super+Shift+E`: terminate the current user session.
- `Super+Space`: toggle the installed-application launcher.
- `Super+Alt+L`: request the shell lock screen.

Inspect the service without restarting it:

```bash
systemctl --user status itterum-shell.service --no-pager
journalctl --user -u itterum-shell.service -b --no-pager
```

Manual recovery tools remain installed during the staged migration:

```bash
fuzzel
swaylock -f
```

## Graphical acceptance checklist

On both a 100% scale output and one scaled output, verify:

- exactly one top bar is visible;
- workspaces, active-window title, clock, and rightmost tray update;
- the launcher contains only the declarative application allowlist;
- launching an item opens an already installed desktop entry;
- killing `itterum-shell` causes one controlled systemd restart;
- `Super+Return` still opens Foot while the shell is stopped;
- the journal has no restart loop or competing layer-shell/protocol owner.

The no-link build has passed. Graphical observations and screenshots remain pending until a disposable VM or target with working Wayland acceleration is available; they are intentionally not inferred from evaluation alone.
