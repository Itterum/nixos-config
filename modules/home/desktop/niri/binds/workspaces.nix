{ ... }:

{
  programs.niri.settings.binds = {
    "Mod+1".action.focus-workspace = 1;
    "Mod+2".action.focus-workspace = 2;
    "Mod+3".action.focus-workspace = 3;
    "Mod+4".action.focus-workspace = 4;
    "Mod+5".action.focus-workspace = 5;
    "Mod+6".action.focus-workspace = 6;
    "Mod+7".action.focus-workspace = 7;
    "Mod+8".action.focus-workspace = 8;
    "Mod+9".action.focus-workspace = 9;

    "Mod+Shift+1".action.move-column-to-workspace = 1;
    "Mod+Shift+2".action.move-column-to-workspace = 2;
    "Mod+Shift+3".action.move-column-to-workspace = 3;
    "Mod+Shift+4".action.move-column-to-workspace = 4;
    "Mod+Shift+5".action.move-column-to-workspace = 5;
    "Mod+Shift+6".action.move-column-to-workspace = 6;
    "Mod+Shift+7".action.move-column-to-workspace = 7;
    "Mod+Shift+8".action.move-column-to-workspace = 8;
    "Mod+Shift+9".action.move-column-to-workspace = 9;

    "Mod+I".action.focus-workspace-up = [ ];
    "Mod+U".action.focus-workspace-down = [ ];
    "Mod+Page_Up".action.focus-workspace-up = [ ];
    "Mod+Page_Down".action.focus-workspace-down = [ ];
    "Mod+Ctrl+Up".action.move-column-to-workspace-up = [ ];
    "Mod+Ctrl+Down".action.move-column-to-workspace-down = [ ];
    "Mod+Shift+I".action.move-workspace-up = [ ];
    "Mod+Shift+U".action.move-workspace-down = [ ];
    "Mod+Shift+Page_Up".action.move-workspace-up = [ ];
    "Mod+Shift+Page_Down".action.move-workspace-down = [ ];

    "Mod+WheelScrollUp" = {
      cooldown-ms = 150;
      action.focus-workspace-up = [ ];
    };
    "Mod+WheelScrollDown" = {
      cooldown-ms = 150;
      action.focus-workspace-down = [ ];
    };
    "Mod+Ctrl+WheelScrollUp" = {
      cooldown-ms = 150;
      action.move-column-to-workspace-up = [ ];
    };
    "Mod+Ctrl+WheelScrollDown" = {
      cooldown-ms = 150;
      action.move-column-to-workspace-down = [ ];
    };
  };
}
