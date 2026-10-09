{ pkgs, ... }:

let
  scpMenuReborn = pkgs.stdenvNoCC.mkDerivation {
    pname = "scp-menu-reborn";
    version = "1.1.1-plasma6.6";

    src = pkgs.fetchFromGitHub {
      owner = "ShrekBytes";
      repo = "scp-menu-reborn";
      rev = "0f90c0fabd171167c7bf5555cf8cbb12e98295fe";
      hash = "sha256-xISUYW8so3zZPy6JP+OKr9uuGgznLeCD3md3IeY5SSs=";
    };

    installPhase = ''
      runHook preInstall

      widget="$out/share/plasma/plasmoids/org.kde.plasma.scpmr"
      mkdir -p "$widget"
      cp -r contents metadata.json "$widget/"

      runHook postInstall
    '';
  };
in
{
  home.packages = [ scpMenuReborn ];

  programs.plasma = {
    enable = true;

    panels = [
      {
        location = "top";
        height = 32;
        floating = false;

        widgets = [
          {
            name = "org.kde.plasma.scpmr";
            config = {
              Apps.appList = builtins.toJSON [
                [
                  "org.kde.kinfocenter.desktop"
                  { iconName = "hwinfo"; }
                ]
                [
                  "systemsettings.desktop"
                  { iconName = "preferences-system"; }
                ]
              ];

              General = {
                icon = "nix-snowflake";
                sessionButtons = builtins.toJSON [
                  {
                    id = "restart";
                    enabled = true;
                  }
                  {
                    id = "sleep";
                    enabled = false;
                  }
                  {
                    id = "shutdown";
                    enabled = true;
                  }
                  {
                    id = "lock";
                    enabled = true;
                  }
                  {
                    id = "logout";
                    enabled = true;
                  }
                  {
                    id = "hibernate";
                    enabled = false;
                  }
                ];
              };
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
