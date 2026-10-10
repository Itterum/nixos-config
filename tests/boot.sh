#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
settings="$(nix eval --json --impure --expr "
  let
    pc = (builtins.getFlake \"path:$root\").nixosConfigurations.pc;
    config = pc.config;
  in {
    systemdBoot = config.boot.loader.systemd-boot.enable;
    canTouchEfiVariables = config.boot.loader.efi.canTouchEfiVariables;
    packages = {
      sbctl = builtins.elem pc.pkgs.sbctl config.environment.systemPackages;
      age = builtins.elem pc.pkgs.age config.environment.systemPackages;
    };
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
  .limine.secureBoot.enable == true and
  .limine.secureBoot.autoGenerateKeys == true and
  .limine.secureBoot.autoEnrollKeys == false and
  .packages.sbctl == true and
  .packages.age == true
' <<<"$settings" >/dev/null

echo "Limine boot configuration assertions passed"
