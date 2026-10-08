{ pkgs, ... }:

let
  webLanguage = name: {
    inherit name;
    language-servers = [ "typescript-language-server" ];
    formatter = {
      command = "${pkgs.prettier}/bin/prettier";
      args = [
        "--stdin-filepath"
        "%{buffer_name}"
      ];
    };
    auto-format = true;
  };
in
{
  programs.helix.languages = {
    language-server.typescript-language-server = {
      command = "${pkgs.typescript-language-server}/bin/typescript-language-server";
      args = [
        "--stdio"
        "--tsserver-path=${pkgs.typescript}/lib/node_modules/typescript/lib"
      ];
    };

    language = map webLanguage [
      "typescript"
      "tsx"
      "javascript"
      "jsx"
    ];
  };
}
