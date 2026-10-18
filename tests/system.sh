#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
result="$(nix eval --raw --impure --expr "
  let
    flake = builtins.getFlake \"path:$root\";
  in
  assert flake.nixosConfigurations ? nixos;
  let
    system = flake.nixosConfigurations.nixos;
    config = system.config;
    pkgs = system.pkgs;
    user = config.users.users.nixos;
    excluded = config.environment.plasma6.excludePackages;
    groups = user.extraGroups;
    devices = map (fs: fs.device or \"\") (builtins.attrValues config.fileSystems);
    oldDevices = [
      \"/dev/disk/by-uuid/22826afd-20de-4487-a62b-dd5543abad27\"
      \"/dev/disk/by-uuid/87A2-7F01\"
      \"/dev/disk/by-uuid/189c29f7-c963-4f67-b8af-6d03581e08ad\"
      \"/dev/disk/by-uuid/BFB4-A380\"
    ];
  in
  assert flake.inputs.nixpkgs.outPath == flake.inputs.weaselway.inputs.nixpkgs.outPath;
  assert config.networking.hostName == \"nixos\";
  assert config.wsl.enable;
  assert config.wsl.defaultUser == \"nixos\";
  assert user.uid == 1000;
  assert user.home == \"/home/nixos\";
  assert config.users.mutableUsers;
  assert user.initialPassword == null;
  assert config.weaselway.enable;
  assert config.weaselway.session == \"plasma\";
  assert config.services.desktopManager.plasma6.enable;
  assert !config.services.displayManager.sddm.enable;
  assert config.virtualisation.docker.enable;
  assert builtins.all (group: builtins.elem group groups) [ \"docker\" \"render\" \"video\" \"input\" ];
  assert config.hardware.graphics.package == pkgs.weaselway-mesa;
  assert builtins.elem pkgs.brave config.environment.systemPackages;
  assert !config.boot.loader.grub.enable;
  assert !config.boot.loader.systemd-boot.enable;
  assert !config.boot.loader.limine.enable;
  assert builtins.all (device: !(builtins.elem device devices)) oldDevices;
  assert builtins.all (package: builtins.elem package excluded) (with pkgs.kdePackages; [
    elisa
    kwin-x11
    krdp
    plasma-workspace-wallpapers
  ]);
  assert !config.programs.kde-pim.enable;
  assert !config.services.fwupd.enable;
  assert !config.services.orca.enable;
  assert !config.services.speechd.enable;
  assert !config.nix.channel.enable;
  assert config.programs.git.enable;
  assert config.programs.nix-ld.enable;
  assert config.system.stateVersion == \"26.05\";
  \"ok\"
")"

test "$result" = "ok"
echo "Weaselway WSL system assertions passed"
