{ osConfig, ... }:

{
  programs.niri.settings.spawn-at-startup = [
    {
      argv = [ "${osConfig.programs.gtklock.package}/bin/gtklock" ];
    }
    { argv = [ "anyrun" "daemon" ]; }
  ];
}
