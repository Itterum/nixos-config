{
  programs.niri.settings.binds = {
    "Mod+Space" = {
      hotkey-overlay.title = "Application Launcher";
      action.spawn = "fuzzel";
    };
    "Mod+Alt+L" = {
      hotkey-overlay.title = "Lock Screen";
      action.spawn = "swaylock";
    };
    "Mod+M" = {
      hotkey-overlay.title = "Task Manager";
      action.spawn = [
        "ghostty"
        "-e"
        "btop"
      ];
    };
    "Mod+T".action.spawn = "ghostty";
    "Super+Return".action.spawn = "ghostty";
  };
}
