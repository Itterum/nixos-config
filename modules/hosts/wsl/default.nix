{ self, inputs, ... }:

{
  flake.nixosConfigurations.nixos = inputs.weaselway.inputs.nixpkgs.lib.nixosSystem {
    modules = [
      inputs.weaselway.inputs.nixos-wsl.nixosModules.default
      inputs.weaselway.nixosModules.weaselway
      self.nixosModules.wslConfig
    ];
  };
}
