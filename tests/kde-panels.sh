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

jq -e '
  length == 2 and
  any(.[];
    .location == "top" and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.appmenu") != null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.systemtray") != null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.digitalclock") != null) and
    ([.widgets[] | if type == "string" then . else .name end] | index("org.kde.plasma.icontasks") == null)
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

echo "KDE panel layout assertions passed"
