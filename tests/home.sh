#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
result="$(nix eval --raw --impure --expr "
  let
    system = (builtins.getFlake \"path:$root\").nixosConfigurations.nixos;
    config = system.config;
  in
  assert config ? home-manager;
  let
    homeManager = config.home-manager;
    user = homeManager.users.nixos;
    pkgs = system.pkgs;
    packages = user.home.packages;
    extensions = user.programs.zed-editor.extensions;
    github = user.programs.ssh.settings.\"github.com\".data;
  in
  assert homeManager.useGlobalPkgs;
  assert homeManager.useUserPackages;
  assert homeManager.users ? nixos;
  assert !(homeManager.users ? itterum);
  assert user.home.username == \"nixos\";
  assert user.home.homeDirectory == \"/home/nixos\";
  assert user.home.stateVersion == \"26.05\";
  assert user.programs.git.settings.user.name == \"lyashenko.ivan\";
  assert user.programs.git.settings.user.email == \"ivan.lyashenko.it@gmail.com\";
  assert github.HostName == \"github.com\";
  assert github.User == \"git\";
  assert github.IdentityFile == \"~/.ssh/id_ed25519_github\";
  assert github.IdentitiesOnly;
  assert user.programs.helix.enable;
  assert user.programs.zed-editor.enable;
  assert !user.programs.zed-editor.mutableUserSettings;
  assert !user.programs.zed-editor.mutableUserKeymaps;
  assert !user.programs.zed-editor.mutableUserDebug;
  assert builtins.all (extension: builtins.elem extension extensions) [
    \"nix\"
    \"toml\"
    \"lua\"
    \"git-firefly\"
    \"jetbrains-themes\"
    \"kanagawa-themes\"
  ];
  assert builtins.all (package: builtins.elem package packages) (with pkgs; [
    ripgrep
    fd
    jq
    uv
    kubectl
    k9s
  ]);
  \"ok\"
")"

test "$result" = "ok"
echo "NixOS Home Manager assertions passed"
