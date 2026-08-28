{ ... }:

{
  programs.niri.settings.outputs = {
    "HDMI-A-1" = {
      mode = {
        width = 1920;
        height = 1080;
        refresh = 74.973;
      };
      scale = 1.0;
      position = {
        x = 0;
        y = 0;
      };
    };

    "eDP-1" = {
      mode = {
        width = 1920;
        height = 1080;
        refresh = 60.001;
      };
      scale = 1.0;
      position = {
        x = 0;
        y = 1080;
      };
    };
  };
}
