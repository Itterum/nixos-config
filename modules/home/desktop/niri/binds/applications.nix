{ ... }:

{
  programs.niri.settings.binds = {
    "Mod+Space" = {
      hotkey-overlay.title = "Application Launcher";
      action.spawn = [
        "noctalia"
        "msg"
        "panel-toggle"
        "launcher"
      ];
    };
    "Mod+Alt+L" = {
      hotkey-overlay.title = "Lock Screen";
      action.spawn = [
        "noctalia"
        "msg"
        "session"
        "lock"
      ];
    };
    "Mod+M" = {
      hotkey-overlay.title = "Task Manager";
      action.spawn = [
        "ghostty"
        "-e"
        "btop"
      ];
    };
    "Mod+T" = {
      hotkey-overlay.title = "Open Terminal";
      action.spawn = "ghostty";
    };
    "Super+Return" = {
      hotkey-overlay.title = "Open Terminal";
      action.spawn = "ghostty";
    };
  };
}
