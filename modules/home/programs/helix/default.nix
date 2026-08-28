{ pkgs, ... }:

{
  imports = [
    ./editor.nix
    ./languages
  ];

  programs.helix = {
    enable = true;
    defaultEditor = true;

    themes.catppuccin_mocha_transparent = {
      inherits = "catppuccin_mocha";
      "ui.background" = { };
    };

    extraPackages = with pkgs; [
      typescript
      typescript-language-server
      prettier
      rust-analyzer
      basedpyright
      ruff
      csharp-ls
      csharpier
      nixd
      nixfmt
      qt6.qtdeclarative
      vscode-langservers-extracted
      taplo
      marksman
      bash-language-server
      kdlfmt
    ];
  };
}
