{
  description = "Itterum NixOS systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    llm-agents.url = "github:numtide/llm-agents.nix";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.niri-unstable.url = "github:wrvsrx/niri/2ab59b90d55afbbe362a63e2a061afe4b524d8c4";
    };
  };

  outputs =
    inputs@{ nixpkgs, home-manager, ... }:
    let
      mkSystem =
        hostModule:
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs; };

          modules = [
            hostModule
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.itterum = import ./home/itterum;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        laptop = mkSystem ./hosts/laptop;
        desktop = mkSystem ./hosts/desktop;
      };
    };
}
