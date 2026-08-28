{ ... }:

{
  programs.niri.settings.binds = {
    "Mod+H".action.focus-column-left = [ ];
    "Mod+J".action.focus-window-down = [ ];
    "Mod+K".action.focus-window-up = [ ];
    "Mod+L".action.focus-column-right = [ ];
    "Mod+Left".action.focus-column-left = [ ];
    "Mod+Down".action.focus-window-down = [ ];
    "Mod+Up".action.focus-window-up = [ ];
    "Mod+Right".action.focus-column-right = [ ];
    "Mod+Home".action.focus-column-first = [ ];
    "Mod+End".action.focus-column-last = [ ];

    "Mod+Shift+H".action.move-column-left = [ ];
    "Mod+Shift+J".action.move-window-down = [ ];
    "Mod+Shift+K".action.move-window-up = [ ];
    "Mod+Shift+L".action.move-column-right = [ ];
    "Mod+Shift+Left".action.move-column-left = [ ];
    "Mod+Shift+Down".action.move-window-down = [ ];
    "Mod+Shift+Up".action.move-window-up = [ ];
    "Mod+Shift+Right".action.move-column-right = [ ];
    "Mod+Ctrl+Home".action.move-column-to-first = [ ];
    "Mod+Ctrl+End".action.move-column-to-last = [ ];

    "Mod+WheelScrollLeft".action.focus-column-left = [ ];
    "Mod+WheelScrollRight".action.focus-column-right = [ ];
    "Mod+Shift+WheelScrollUp".action.focus-column-left = [ ];
    "Mod+Shift+WheelScrollDown".action.focus-column-right = [ ];
    "Mod+Ctrl+WheelScrollLeft".action.move-column-left = [ ];
    "Mod+Ctrl+WheelScrollRight".action.move-column-right = [ ];

    "Mod+Q" = {
      repeat = false;
      action.close-window = [ ];
    };
    "Mod+R".action.switch-preset-column-width = [ ];
    "Mod+Shift+R".action.switch-preset-window-height = [ ];
    "Mod+Equal".action.set-column-width = "+10%";
    "Mod+Minus".action.set-column-width = "-10%";
    "Mod+Shift+Equal".action.set-window-height = "+10%";
    "Mod+Shift+Minus".action.set-window-height = "-10%";
    "Mod+Ctrl+R".action.reset-window-height = [ ];
    "Mod+F".action.maximize-column = [ ];
    "Mod+Ctrl+F".action.expand-column-to-available-width = [ ];
    "Mod+Shift+F".action.fullscreen-window = [ ];
    "Mod+C".action.center-column = [ ];
    "Mod+Ctrl+C".action.center-visible-columns = [ ];
    "Mod+W".action.toggle-column-tabbed-display = [ ];
    "Mod+Period".action.expel-window-from-column = [ ];
    "Mod+BracketLeft".action.consume-or-expel-window-left = [ ];
    "Mod+BracketRight".action.consume-or-expel-window-right = [ ];
    "Mod+Shift+T".action.toggle-window-floating = [ ];
    "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = [ ];
  };
}
