{ ... }:

{
  programs.niri.settings.binds = {
    "Mod+Ctrl+H".action.focus-monitor-left = [ ];
    "Mod+Ctrl+J".action.focus-monitor-down = [ ];
    "Mod+Ctrl+K".action.focus-monitor-up = [ ];
    "Mod+Ctrl+L".action.focus-monitor-right = [ ];
    "Mod+Ctrl+Left".action.focus-monitor-left = [ ];
    "Mod+Ctrl+Right".action.focus-monitor-right = [ ];

    "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = [ ];
    "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = [ ];
    "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = [ ];
    "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = [ ];
    "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = [ ];
    "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = [ ];
    "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = [ ];
    "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = [ ];
  };
}
