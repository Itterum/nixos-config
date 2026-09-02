{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.codex-cli.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
