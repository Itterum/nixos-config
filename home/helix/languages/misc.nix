{ pkgs, ... }:

{
  programs.helix.languages = {
    language-server = {
      vscode-json-language-server = {
        command = "${pkgs.vscode-langservers-extracted}/bin/vscode-json-language-server";
        args = [ "--stdio" ];
      };
      taplo = {
        command = "${pkgs.taplo}/bin/taplo";
        args = [
          "lsp"
          "stdio"
        ];
      };
      marksman = {
        command = "${pkgs.marksman}/bin/marksman";
        args = [ "server" ];
      };
      bash-language-server = {
        command = "${pkgs.bash-language-server}/bin/bash-language-server";
        args = [ "start" ];
      };
      nixd.command = "${pkgs.nixd}/bin/nixd";
    };

    language = [
      {
        name = "nix";
        language-servers = [ "nixd" ];
        formatter.command = "${pkgs.nixfmt}/bin/nixfmt";
        auto-format = true;
      }
      {
        name = "json";
        language-servers = [ "vscode-json-language-server" ];
      }
      {
        name = "toml";
        language-servers = [ "taplo" ];
      }
      {
        name = "markdown";
        language-servers = [ "marksman" ];
      }
      {
        name = "bash";
        language-servers = [ "bash-language-server" ];
      }
    ];
  };
}
