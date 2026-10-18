#!/usr/bin/env bash
set -euo pipefail

root="$(git rev-parse --show-toplevel)"
wallpaper="$(nix eval --raw --impure --expr "
  let
    system = (builtins.getFlake \"path:$root\").nixosConfigurations.nixos;
    config = system.config;
    pkgs = system.pkgs;
    user = config.home-manager.users.nixos;
  in
  assert user.programs ? plasma;
  let
    plasma = user.programs.plasma;
    panels = plasma.panels;
    top = builtins.elemAt panels 0;
    dock = builtins.elemAt panels 1;
    topObjects = builtins.filter builtins.isAttrs top.widgets;
    menu = builtins.head (builtins.filter (widget: (widget.name or \"\") == \"com.github.edmogeor.kppleMenu\") topObjects);
    clock = builtins.head (builtins.filter (widget: (widget.name or \"\") == \"org.kde.plasma.digitalclock\") topObjects);
    dockWidget = builtins.head (builtins.filter builtins.isAttrs dock.widgets);
    menuItems = builtins.fromJSON menu.config.General.menuItems;
    expectedMenuItems = [
      { type = \"item\"; name = \"About This Computer\"; command = \"kinfocenter\"; }
      { type = \"divider\"; }
      { type = \"item\"; name = \"System Preferences...\"; command = \"systemsettings\"; }
      { type = \"divider\"; }
      { type = \"item\"; name = \"Lock Screen\"; command = \"qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock\"; shortcut = \"⌃⌘Q\"; }
      { type = \"item\"; name = \"Log Out\"; command = \"qdbus org.kde.LogoutPrompt /LogoutPrompt promptLogout\"; shortcut = \"⇧⌘Q\"; }
    ];
    packageName = package: package.pname or package.name or \"\";
  in
  assert plasma.enable;
  assert user.programs.foot.enable;
  assert builtins.elem pkgs.kdePackages.konsole config.environment.plasma6.excludePackages;
  assert user.programs.foot.settings.main.font == \"JetBrains Mono:size=12\";
  assert user.programs.foot.settings.main.\"initial-window-size-chars\" == \"111x33\";
  assert user.programs.plasma.configFile.\"kdeglobals\".General.TerminalApplication.value == \"foot\";
  assert user.programs.plasma.configFile.\"kdeglobals\".General.TerminalService.value == \"foot.desktop\";
  assert plasma.workspace.iconTheme == \"WhiteSur-dark\";
  assert plasma.workspace.cursor.theme == \"WhiteSur-cursors\";
  assert plasma.workspace.wallpaper == plasma.kscreenlocker.appearance.wallpaper;
  assert builtins.elem pkgs.whitesur-icon-theme user.home.packages;
  assert builtins.elem pkgs.whitesur-cursors user.home.packages;
  assert builtins.any (package: packageName package == \"kpple-menu\") user.home.packages;
  assert builtins.length panels == 2;
  assert top.location == \"top\";
  assert top.height == 32;
  assert !top.floating;
  assert clock.config.Appearance.showDate == false;
  assert clock.config.Appearance.showSeconds == 2;
  assert clock.config.Appearance.use24hFormat == 2;
  assert dock.location == \"bottom\";
  assert dock.height == 48;
  assert dock.floating;
  assert dock.alignment == \"center\";
  assert dock.lengthMode == \"fit\";
  assert dock.hiding == \"dodgewindows\";
  assert dockWidget.name == \"org.kde.plasma.icontasks\";
  assert dockWidget.config.General.launchers == [
    \"applications:org.kde.dolphin.desktop\"
    \"applications:foot.desktop\"
    \"applications:com.brave.Browser.desktop\"
    \"applications:dev.zed.Zed.desktop\"
  ];
  assert menuItems == expectedMenuItems;
  toString plasma.workspace.wallpaper
")"

test -f "$wallpaper"
test "$(sha256sum "$wallpaper" | cut -d' ' -f1)" = "06a381bd115716b5ff40b23bd0e2c021ca5b6e2507fe350c2bdef2a827d8fa62"

echo "Weaselway KDE assertions passed"
