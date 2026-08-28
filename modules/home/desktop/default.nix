{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}:

let
  colors = {
    base = "1e1e2e";
    surface0 = "313244";
    surface1 = "45475a";
    overlay0 = "6c7086";
    text = "cdd6f4";
    subtext0 = "a6adc8";
    mauve = "cba6f7";
    blue = "89b4fa";
    green = "a6e3a1";
    yellow = "f9e2af";
    red = "f38ba8";
  };
  cursorName = "macOS";
  cursorSize = 24;
  gtkThemeName = "catppuccin-mocha-mauve-standard+normal";
  gtkThemePackage = pkgs.catppuccin-gtk.override {
    accents = [ "mauve" ];
    size = "standard";
    tweaks = [ "normal" ];
    variant = "mocha";
  };
  qtThemeName = "catppuccin-mocha-mauve";
  qtThemePackage = pkgs.catppuccin-kvantum.override {
    accent = "mauve";
    variant = "mocha";
  };
  lockCommand = "${pkgs.swaylock}/bin/swaylock -f";
in
{
  home.activation.installNiriConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.configHome}/niri"
    run install -m 0644 "${../../../home/itterum/files/niri/config.kdl}" "${config.xdg.configHome}/niri/config.kdl"
  '';

  home.packages = with pkgs; [
    tree
    ripgrep
    brightnessctl
  ];



  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "FiraCode Nerd Font:size=14";
        terminal = "ghostty";
        layer = "overlay";
        prompt = "❯  ";
        icon-theme = "Papirus-Dark";
        icons-enabled = true;
        width = 42;
        lines = 12;
        horizontal-pad = 20;
        vertical-pad = 14;
        inner-pad = 8;
      };

      colors = {
        background = "${colors.base}f2";
        text = "${colors.text}ff";
        prompt = "${colors.mauve}ff";
        placeholder = "${colors.overlay0}ff";
        input = "${colors.text}ff";
        match = "${colors.mauve}ff";
        selection = "${colors.surface0}ff";
        selection-text = "${colors.text}ff";
        selection-match = "${colors.mauve}ff";
        counter = "${colors.subtext0}ff";
        border = "${colors.mauve}ff";
      };

      border = {
        width = 2;
        radius = 10;
      };
    };
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = colors.base;
      font = "FiraCode Nerd Font";
      font-size = 24;
      indicator-radius = 100;
      indicator-thickness = 8;
      inside-color = "${colors.base}cc";
      inside-clear-color = "${colors.yellow}cc";
      inside-ver-color = "${colors.blue}cc";
      inside-wrong-color = "${colors.red}cc";
      ring-color = colors.surface1;
      ring-clear-color = colors.yellow;
      ring-ver-color = colors.blue;
      ring-wrong-color = colors.red;
      key-hl-color = colors.mauve;
      bs-hl-color = colors.red;
      text-color = colors.text;
      text-clear-color = colors.base;
      text-ver-color = colors.base;
      text-wrong-color = colors.base;
      separator-color = "00000000";
      ignore-empty-password = true;
      show-failed-attempts = true;
    };
  };

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = lockCommand;
      lock = lockCommand;
    };
    timeouts = [
      {
        timeout = 300;
        command = lockCommand;
      }
      {
        timeout = 600;
        command = "${pkgs.niri}/bin/niri msg action power-off-monitors";
        resumeCommand = "${pkgs.niri}/bin/niri msg action power-on-monitors";
      }
    ]
    ++ lib.optionals osConfig.services.tlp.enable [
      {
        timeout = 1800;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
  };

  home.pointerCursor = {
    package = pkgs.apple-cursor;
    name = cursorName;
    size = cursorSize;

    gtk.enable = true;
    x11.enable = true;
  };

  gtk = {
    enable = true;

    theme = {
      package = gtkThemePackage;
      name = gtkThemeName;
    };

    iconTheme = {
      package = pkgs.papirus-icon-theme;
      name = "Papirus-Dark";
    };

    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme.name = "qtct";
    style.name = "kvantum";

    kvantum = {
      enable = true;
      themes = [ qtThemePackage ];
      settings.General.theme = qtThemeName;
    };

    qt5ctSettings.Appearance = {
      icon_theme = "Papirus-Dark";
      standard_dialogs = "xdgdesktopportal";
      style = "kvantum";
    };
    qt6ctSettings.Appearance = {
      icon_theme = "Papirus-Dark";
      standard_dialogs = "xdgdesktopportal";
      style = "kvantum";
    };
  };

  xdg.configFile."qt5ct/qt5ct.conf".force = true;
  xdg.configFile."qt6ct/qt6ct.conf".force = true;

  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    cursor-size = cursorSize;
    cursor-theme = cursorName;
    gtk-theme = gtkThemeName;
    icon-theme = "Papirus-Dark";
  };
}
