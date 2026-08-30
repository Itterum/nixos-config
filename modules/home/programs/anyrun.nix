{ pkgs, ... }:

{
  programs.anyrun = {
    enable = true;

    config = {
      x.fraction = 0.5;
      y.fraction = 0.3;
      width.fraction = 0.3;

      layer = "overlay";
      hideIcons = false;
      hidePluginInfo = true;

      plugins = [
        "${pkgs.anyrun}/lib/libapplications.so"
        "${pkgs.anyrun}/lib/librink.so"
        "${pkgs.anyrun}/lib/libwebsearch.so"
        "${pkgs.anyrun}/lib/libniri_focus.so"
        "${pkgs.anyrun}/lib/libactions.so"
        "${pkgs.anyrun}/lib/libshell.so"
      ];
    };
  };
}
