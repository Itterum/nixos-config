{ lib, ... }:

{
  options.flake.homeModules = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.deferredModule;
    default = { };
    description = "Home Manager modules exported by this flake.";
  };
}
