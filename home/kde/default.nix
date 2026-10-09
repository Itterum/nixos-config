{ pkgs, ... }:

let
  kppleMenu = pkgs.stdenvNoCC.mkDerivation {
    pname = "kpple-menu";
    version = "6.1";

    src = pkgs.fetchFromGitHub {
      owner = "edmogeor";
      repo = "kppleMenu";
      rev = "d3dd8823bda538c125d976641848005cd1a38625";
      hash = "sha256-IZfsO/lOpDzbMUAj1Z93O1HWgMgTpUx1Jr8RGrHx/jA=";
    };

    installPhase = ''
      runHook preInstall

      widget="$out/share/plasma/plasmoids/com.github.edmogeor.kppleMenu"
      mkdir -p "$widget"
      cp -r package/contents package/metadata.json "$widget/"

      runHook postInstall
    '';
  };
in
{
  home.packages = with pkgs; [
    kppleMenu
    whitesur-cursors
    whitesur-icon-theme
  ];

  programs.plasma = {
    enable = true;

    workspace = {
      iconTheme = "WhiteSur-dark";
      cursor.theme = "WhiteSur-cursors";
    };

    panels = [
      {
        location = "top";
        height = 32;
        floating = false;

        widgets = [
          {
            name = "com.github.edmogeor.kppleMenu";
            config.General = {
              icon = "nix-snowflake";
              menuItems = builtins.toJSON [
                {
                  type = "item";
                  name = "About This Computer";
                  command = "kinfocenter";
                }
                { type = "divider"; }
                {
                  type = "item";
                  name = "System Preferences...";
                  command = "systemsettings";
                }
                {
                  type = "item";
                  name = "App Store...";
                  command = "plasma-discover";
                }
                { type = "divider"; }
                {
                  type = "item";
                  name = "Restart...";
                  command = "qdbus org.kde.LogoutPrompt /LogoutPrompt promptReboot";
                }
                {
                  type = "item";
                  name = "Shut Down...";
                  command = "qdbus org.kde.LogoutPrompt /LogoutPrompt promptShutDown";
                }
                { type = "divider"; }
                {
                  type = "item";
                  name = "Lock Screen";
                  command = "qdbus org.freedesktop.ScreenSaver /ScreenSaver Lock";
                  shortcut = "⌃⌘Q";
                }
                {
                  type = "item";
                  name = "Log Out";
                  command = "qdbus org.kde.LogoutPrompt /LogoutPrompt promptLogout";
                  shortcut = "⇧⌘Q";
                }
              ];
            };
          }
          "org.kde.plasma.appmenu"
          "org.kde.plasma.panelspacer"
          "org.kde.plasma.systemtray"
          "org.kde.plasma.digitalclock"
        ];
      }

      {
        location = "bottom";
        height = 48;
        floating = true;
        alignment = "center";
        lengthMode = "fit";
        hiding = "dodgewindows";

        widgets = [
          {
            name = "org.kde.plasma.icontasks";
            config.General.launchers = [
              "applications:org.kde.dolphin.desktop"
              "applications:foot.desktop"
              "applications:com.google.Chrome.desktop"
              "applications:com.brave.Browser.desktop"
              "applications:dev.zed.Zed.desktop"
              "applications:steam.desktop"
              "applications:jetbrains-idea-7606aa57-547c-45b5-99a7-6cf98e137b1d.desktop"
            ];
          }
        ];
      }
    ];
  };
}
