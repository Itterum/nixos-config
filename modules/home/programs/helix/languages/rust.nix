{ pkgs, ... }:

{
  programs.helix.languages = {
    language-server.rust-analyzer = {
      command = "${pkgs.rust-analyzer}/bin/rust-analyzer";
      config = {
        check = {
          command = "clippy";
          allTargets = true;
        };
        cargo.buildScripts.enable = true;
        procMacro.enable = true;
        completion.fullFunctionSignatures.enable = true;
        imports.granularity.group = "module";
        inlayHints = {
          bindingModeHints.enable = true;
          closureReturnTypeHints.enable = "with_block";
          lifetimeElisionHints = {
            enable = "skip_trivial";
            useParameterNames = true;
          };
        };
      };
    };

    language = [
      {
        name = "rust";
        roots = [
          "Cargo.toml"
          "Cargo.lock"
        ];
        language-servers = [ "rust-analyzer" ];
        auto-format = true;
      }
    ];
  };
}
