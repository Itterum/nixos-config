#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
settings="$(nix eval --json --impure --expr "
  let
    config = (builtins.getFlake \"path:$root\").nixosConfigurations.pc.config;
  in {
    systemdBoot = config.boot.loader.systemd-boot.enable;
    canTouchEfiVariables = config.boot.loader.efi.canTouchEfiVariables;
    limine = {
      inherit (config.boot.loader.limine)
        enable
        efiSupport
        biosSupport
        efiInstallAsRemovable
        enableEditor
        maxGenerations
        ;
      secureBoot = {
        inherit (config.boot.loader.limine.secureBoot)
          enable
          autoGenerateKeys
          ;
        autoEnrollKeys = config.boot.loader.limine.secureBoot.autoEnrollKeys.enable;
      };
    };
  }
")"

jq -e '
  .systemdBoot == false and
  .canTouchEfiVariables == true and
  .limine.enable == true and
  .limine.efiSupport == true and
  .limine.biosSupport == false and
  .limine.efiInstallAsRemovable == false and
  .limine.enableEditor == false and
  .limine.maxGenerations == 10 and
  .limine.secureBoot.enable == false and
  .limine.secureBoot.autoGenerateKeys == false and
  .limine.secureBoot.autoEnrollKeys == false
' <<<"$settings" >/dev/null

echo "Limine boot configuration assertions passed"
