{ ... }:

{
  dconf.settings = {
    "org/gnome/desktop/input-sources".xkb-options = [ "ctrl:nocaps" ];

    "org/gnome/desktop/interface".clock-show-seconds = true;

    "org/gnome/shell/extensions/appindicator".tray-pos = "right";

    "org/gnome/shell/extensions/caffeine" = {
      cli-toggle = true;
      indicator-position-max = 2;
      restore-state = true;
      user-enabled = true;
    };

    "org/gnome/shell/extensions/dash2dock-lite" = {
      animation-bounce-height = 0.75;
      animation-magnify = 0.0;
      animation-rise = 0.25;
      animation-spread = 0.75;
      apps-icon = false;
      apps-icon-front = false;
      autohide-dash = true;
      autohide-speed = 0.5;
      blur-background = false;
      border-radius = 3.0;
      calendar-icon = true;
      clock-icon = false;
      dock-padding = 1.0;
      downloads-icon = true;
      downloads-path = "";
      edge-distance = 0.56976744186046502;
      icon-border-radius = 3.0;
      icon-spacing = 0.0;
      items-pullout-angle = 0.5;
      mounted-icon = true;
      msg-to-ext = "";
      overview-transparent-background = true;
      panel-mode = false;
      preferred-monitor = 0;
      pressure-sense = false;
      pressure-sense-sensitivity = 0.40000000000000002;
      running-indicator-style = 1;
      scroll-sensitivity = 0.40000000000000002;
      shrink-icons = false;
      trash-icon = true;
    };

    "org/gnome/shell/extensions/globalmenu" = {
      hide-overview-button = true;
      logo-custom-icon-path = "";
      logo-distro-icon = "";
      logo-distro-icon-symbolic = true;
      logo-icon-size = 16;
    };

    "org/gnome/shell/extensions/just-perfection" = {
      clock-menu-position = 1;
      clock-menu-position-offset = 2;
      notification-banner-position = 2;
    };
  };
}
