{ pkgs, ... }:

{
  programs.helix.languages = {
    language-server = {
      basedpyright = {
        command = "${pkgs.basedpyright}/bin/basedpyright-langserver";
        args = [ "--stdio" ];
      };
      ruff = {
        command = "${pkgs.ruff}/bin/ruff";
        args = [ "server" ];
      };
    };

    language = [
      {
        name = "python";
        roots = [
          "pyproject.toml"
          "uv.lock"
          "requirements.txt"
          ".git"
        ];
        language-servers = [
          "basedpyright"
          {
            name = "ruff";
            only-features = [
              "diagnostics"
              "code-action"
            ];
          }
        ];
        formatter = {
          command = "${pkgs.ruff}/bin/ruff";
          args = [
            "format"
            "-"
          ];
        };
        auto-format = true;
      }
    ];
  };
}
