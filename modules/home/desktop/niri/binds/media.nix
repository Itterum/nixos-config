{ pkgs, ... }:

{
  home.packages = with pkgs; [
    brightnessctl
    playerctl
  ];

  programs.niri.settings.binds = {
    "XF86AudioLowerVolume" = {
      allow-when-locked = true;
      action.spawn = [
        "wpctl"
        "set-volume"
        "@DEFAULT_AUDIO_SINK@"
        "3%-"
      ];
    };
    "XF86AudioRaiseVolume" = {
      allow-when-locked = true;
      action.spawn = [
        "wpctl"
        "set-volume"
        "-l"
        "1.0"
        "@DEFAULT_AUDIO_SINK@"
        "3%+"
      ];
    };
    "XF86AudioMute" = {
      allow-when-locked = true;
      action.spawn = [
        "wpctl"
        "set-mute"
        "@DEFAULT_AUDIO_SINK@"
        "toggle"
      ];
    };
    "XF86AudioMicMute" = {
      allow-when-locked = true;
      action.spawn = [
        "wpctl"
        "set-mute"
        "@DEFAULT_AUDIO_SOURCE@"
        "toggle"
      ];
    };
    "XF86AudioPrev" = {
      allow-when-locked = true;
      action.spawn = [
        "playerctl"
        "previous"
      ];
    };
    "XF86AudioPlay" = {
      allow-when-locked = true;
      action.spawn = [
        "playerctl"
        "play-pause"
      ];
    };
    "XF86AudioPause" = {
      allow-when-locked = true;
      action.spawn = [
        "playerctl"
        "play-pause"
      ];
    };
    "XF86AudioNext" = {
      allow-when-locked = true;
      action.spawn = [
        "playerctl"
        "next"
      ];
    };
    "XF86MonBrightnessDown" = {
      allow-when-locked = true;
      action.spawn = [
        "brightnessctl"
        "set"
        "5%-"
      ];
    };
    "XF86MonBrightnessUp" = {
      allow-when-locked = true;
      action.spawn = [
        "brightnessctl"
        "set"
        "+5%"
      ];
    };
  };
}
