{ pkgs, ... }:

{
  imports = [
    ./settings.nix
    ./keymaps.nix
  ];

  programs.zed-editor = {
    enable = true;

    mutableUserSettings = false;
    mutableUserKeymaps = false;
    mutableUserDebug = false;

    extensions = [
      "nix"
      "toml"
      "lua"
      "git-firefly"
      "jetbrains-themes"
      "kanagawa-themes"
    ];

    extraPackages = with pkgs; [
      nixd
    ];
  };
}
