{ self, inputs, ... }: {
  flake.nixosModules.gptApp = { pkgs, lib, ... }: {
    environment.systemPackages = [
      inputs.nixos-chatgpt.packages.${pkgs.system}.chatgpt
    ];
  };
}
