{ self, inputs, ... }:

let
  mkVm =
    desktopModule:
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        self.nixosModules.vmConfig
        desktopModule
      ];
    };
  vmGnome = mkVm self.nixosModules.vmGnome;
  vmKde = mkVm self.nixosModules.vmKde;
in
{
  flake.nixosConfigurations = {
    vm-gnome = vmGnome;
    vm-kde = vmKde;

    # Preserve the original profile name for existing rebuild commands.
    vm = vmGnome;
  };
}
