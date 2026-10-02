{
  programs.zed-editor.userKeymaps = [
    {
      context = "!ProjectPanel";
      bindings."alt-e" = "project_panel::ToggleFocus";
    }
    {
      context = "Workspace";
      bindings = {
        "alt-l" = "workspace::ToggleLeftDock";
        "alt-r" = "workspace::ToggleRightDock";
        "alt-b" = "workspace::ToggleBottomDock";
        "alt-g" = "git_panel::ToggleFocus";
        "alt-d" = "debug_panel::ToggleFocus";
        "alt-o" = "projects::OpenRecent";
      };
    }
    {
      context = "!Editor";
      bindings."alt-e" = "editor::ToggleFocus";
    }
    {
      context = "Workspace";
      bindings."shift shift" = "file_finder::Toggle";
    }
  ];
}
