{ pkgs, ... }:

{
  imports = [
    ./editor.nix
    ./languages
  ];

  programs.helix = {
    enable = true;
    defaultEditor = true;

    themes.transparent_theme = {
      inherits = "jetbrains_dark";
      "ui.background" = { };
    };

    extraPackages = with pkgs; [
      typescript
      typescript-language-server
      prettier
      rust-analyzer
      basedpyright
      ruff
      nixd
      nixfmt
      vscode-langservers-extracted
      taplo
      marksman
      bash-language-server
    ];
  };
}
