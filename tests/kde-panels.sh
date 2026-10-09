#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
flake="builtins.getFlake \"path:$root\""
panels="$(nix eval --json --impure --expr "
  let
    user = ($flake).nixosConfigurations.pc.config.home-manager.users.itterum;
  in
    user.programs.plasma.panels or []
")"
appearance="$(nix eval --json --impure --expr "
  let
    pc = ($flake).nixosConfigurations.pc;
    user = pc.config.home-manager.users.itterum;
  in {
    iconTheme = user.programs.plasma.workspace.iconTheme or null;
    cursorTheme = user.programs.plasma.workspace.cursor.theme or null;
    iconPackage = builtins.elem pc.pkgs.whitesur-icon-theme user.home.packages;
    cursorPackage = builtins.elem pc.pkgs.whitesur-cursors user.home.packages;
    menuPackage = builtins.any (package: (package.pname or package.name or \"\") == \"kpple-menu\") user.home.packages;
  }
")"

jq -e '
  length == 2 and
  any(.[];
    .location == "top" and
    ([.widgets[] | select(type == "object" and .name == "com.github.edmogeor.kppleMenu")] | length == 1) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.kickoff") == null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.scpmr") == null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.appmenu") != null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.systemtray") != null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.digitalclock") != null) and
    any(.widgets[];
      type == "object" and
      .name == "org.kde.plasma.digitalclock" and
      .config.Appearance.showDate == false and
      .config.Appearance.showSeconds == 2 and
      .config.Appearance.use24hFormat == 2
    ) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.icontasks") == null) and
    ([.widgets[] | select(type == "object" and .name == "com.github.edmogeor.kppleMenu")][0] as $menu |
      $menu.config.General.icon == "nix-snowflake" and
      ($menu.config.General.menuItems | fromjson) == [
        {"type": "item", "name": "About This Computer", "command": "kinfocenter"},
        {"type": "divider"},
        {"type": "item", "name": "System Preferences...", "command": "systemsettings"},
        {"type": "item", "name": "App Store...", "command": "plasma-discover"},
        {"type": "divider"},
        {"type": "item", "name": "Restart...", "command": "qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot"},
        {"type": "item", "name": "Shut Down...", "command": "qdbus org.kde.LogoutPrompt /LogoutPrompt promptShutDown"},
        {"type": "divider"},
        {"type": "item", "name": "Lock Screen", "command": "qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock", "shortcut": "⌃⌘Q"},
        {"type": "item", "name": "Log Out", "command": "qdbus org.kde.LogoutPrompt /LogoutPrompt promptLogout", "shortcut": "⇧⌘Q"}
      ]
    )
  ) and
  any(.[];
    .location == "bottom" and
    .floating == true and
    .alignment == "center" and
    .lengthMode == "fit" and
    .hiding == "dodgewindows" and
    any(.widgets[];
      type == "object" and
      .name == "org.kde.plasma.icontasks" and
      .config.General.launchers == [
        "applications:org.kde.dolphin.desktop",
        "applications:foot.desktop",
        "applications:com.google.Chrome.desktop",
        "applications:com.brave.Browser.desktop",
        "applications:dev.zed.Zed.desktop",
        "applications:steam.desktop",
        "applications:jetbrains-idea-7606aa57-547c-45b5-99a7-6cf98e137b1d.desktop"
      ]
    )
  )
' <<<"$panels" >/dev/null
jq -e '
  .iconTheme == "WhiteSur-dark" and
  .cursorTheme == "WhiteSur-cursors" and
  .iconPackage == true and
  .cursorPackage == true and
  .menuPackage == true
' <<<"$appearance" >/dev/null

echo "KDE panel layout assertions passed"
