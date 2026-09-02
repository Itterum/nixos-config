{ pkgs, ... }:

{
  services = {
    flatpak.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    upower.enable = true;
    ollama = {
      enable = true;
      package = pkgs.ollama-cuda;

      loadModels = [
        "rnj-1:8b"
        "qwen2.5-coder:7b"
      ];
    };
  };
}
