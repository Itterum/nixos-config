#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
flake="builtins.getFlake \"path:$root\""
state="$(nix eval --json --impure --expr "
  let
    pc = ($flake).nixosConfigurations.pc;
    user = pc.config.home-manager.users.itterum;
  in {
    packageInstalled = builtins.elem pc.pkgs.caffeine-ng user.home.packages;
    service = user.systemd.user.services.caffeine-ng or {};
  }
")"

jq -e '
  .packageInstalled == true and
  (.service.Service.ExecStart | any(endswith("/bin/caffeine"))) and
  (.service.Unit.PartOf | index("graphical-session.target") != null) and
  (.service.Install.WantedBy | index("graphical-session.target") != null)
' <<<"$state" >/dev/null

echo "Caffeine NG package and autostart assertions passed"
