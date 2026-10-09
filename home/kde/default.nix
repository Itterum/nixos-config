{ ... }:

{
  programs.plasma = {
    enable = true;

    panels = [
      {
        location = "top";
        height = 32;
        floating = false;

        widgets = [
          "org.kde.plasma.kickoff"
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
