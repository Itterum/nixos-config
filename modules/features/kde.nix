{ inputs, ... }:

{
  flake.homeModules.kde = {
    imports = [
      inputs.plasma-manager.homeModules.plasma-manager
      ../../home/kde
    ];
  };
}
