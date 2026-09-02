{ ... }:
{
  time.timeZone = "Europe/Minsk";
  i18n.defaultLocale = "en_US.UTF-8";

  services.xserver.xkb = {
    layout = "us,ru";
    variant = "";
    options = "ctrl:nocaps,grp:shifts_toggle";
  };
}
