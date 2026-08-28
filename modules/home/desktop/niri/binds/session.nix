{ ... }:

{
  programs.niri.settings.binds = {
    Print.action.screenshot = [ ];
    "Ctrl+Print".action.screenshot-screen = [ ];
    "Alt+Print".action.screenshot-window = [ ];
    XF86Launch1.action.screenshot = [ ];
    "Ctrl+XF86Launch1".action.screenshot-screen = [ ];
    "Alt+XF86Launch1".action.screenshot-window = [ ];

    "Mod+D" = {
      repeat = false;
      action.toggle-overview = [ ];
    };
    "Mod+Tab" = {
      repeat = false;
      action.toggle-overview = [ ];
    };
    "Mod+Shift+P".action.power-off-monitors = [ ];
    "Mod+Escape" = {
      allow-inhibiting = false;
      action.toggle-keyboard-shortcuts-inhibit = [ ];
    };
    "Mod+Shift+Slash".action.show-hotkey-overlay = [ ];
    "Mod+Shift+E".action.quit = [ ];
  };
}
