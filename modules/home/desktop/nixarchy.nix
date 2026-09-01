{ inputs, ... }:

{
  imports = [
    inputs.nixarchy.homeManagerModules.nixarchy
  ];

  programs.nixarchy.enable = true;
}
