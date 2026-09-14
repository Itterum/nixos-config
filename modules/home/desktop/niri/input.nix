{ ... }:

{
  programs.niri.settings = {
    gestures.hot-corners.enable = false;

    input = {
      keyboard.numlock = true;
      touchpad = {
        tap = true;
        natural-scroll = true;
      };
    };

    cursor = {
      theme = "macOS";
      size = 24;
    };
  };
}
