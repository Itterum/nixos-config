{ inputs, pkgs, ... }:

{
  home.packages = [
    inputs.herdr-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
