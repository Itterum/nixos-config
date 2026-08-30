{ ... }:

{
  programs.niri.settings.binds = {
    "Mod+Space" = {
      hotkey-overlay.title = "Application Launcher";
      action.spawn = "anyrun";
    };
    "Mod+Alt+L" = {
      hotkey-overlay.title = "Lock Screen";
      action.spawn = [
        "gtklock"
        "--daemonize"
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
