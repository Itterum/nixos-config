{ config, pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    settings = {
      default_mode = "locked";
      default_layout = "default";
      pane_frames = false;
    };
    layouts.default = ''
      layout {
          default_tab_template {
              children
              pane size=1 borderless=true {
                  plugin location="file:${config.xdg.configHome}/zellij/plugins/zjstatus.wasm" {
                      format_left   "{mode}"
                      format_center "{tabs}"
                      format_right  "#[fg=#808080] {session} "
                      format_space  ""

                      border_enabled "false"

                      mode_normal          "#[fg=#A9B7C6,bold] {name} "
                      mode_locked          "#[fg=#CC7832,bold] {name} "
                      mode_default_to_mode "normal"

                      tab_normal "#[fg=#808080] {index}:{name} "
                      tab_active "#[fg=#A9B7C6,bold] {index}:{name} "
                  }
              }
          }
      }
    '';
  };

  xdg.configFile."zellij/plugins/zjstatus.wasm".source = pkgs.zellijPlugins.zjstatus;
}
