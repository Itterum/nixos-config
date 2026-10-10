#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
settings="$(nix eval --json --impure --expr "
  let
    config = (builtins.getFlake \"path:$root\").nixosConfigurations.pc.config;
  in {
    automatic = config.nix.gc.automatic;
    dates = config.nix.gc.dates;
    options = config.nix.gc.options;
  }
")"

jq -e '
  .automatic == true and
  .dates == ["weekly"] and
  .options == "--delete-older-than 14d"
' <<<"$settings" >/dev/null

echo "Nix maintenance assertions passed"
