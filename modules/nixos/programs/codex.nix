{ inputs, pkgs, ... }:

{
  environment.systemPackages = [
    inputs.codex-cli.packages.${pkgs.system}.default
  ];
}
