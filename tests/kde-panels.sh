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
system_menu_installed="$(nix eval --json --impure --expr "
  let
    user = ($flake).nixosConfigurations.pc.config.home-manager.users.itterum;
  in
    builtins.any (package: (package.pname or package.name or \"\") == \"scp-menu-reborn\") user.home.packages
")"

jq -e '
  length == 2 and
  any(.[];
    .location == "top" and
    ([.widgets[] | select(type == "object" and .name == "org.kde.plasma.scpmr")] | length == 1) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.kickoff") == null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.appmenu") != null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.systemtray") != null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.digitalclock") != null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.icontasks") == null) and
    ([.widgets[] | select(type == "object" and .name == "org.kde.plasma.scpmr")][0] as $menu |
      $menu.config.General.icon == "nix-snowflake" and
      ($menu.config.Apps.appList | fromjson) == [
        ["org.kde.kinfocenter.desktop", {"iconName": "hwinfo"}],
        ["systemsettings.desktop", {"iconName": "preferences-system"}]
      ] and
      ($menu.config.General.sessionButtons | fromjson) == [
        {"id": "restart", "enabled": true},
        {"id": "sleep", "enabled": false},
        {"id": "shutdown", "enabled": true},
        {"id": "lock", "enabled": true},
        {"id": "logout", "enabled": true},
        {"id": "hibernate", "enabled": false}
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
test "$system_menu_installed" = true

echo "KDE panel layout assertions passed"
