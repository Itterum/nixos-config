{
  security.polkit.enable = true;
  services = {
    gnome.gnome-keyring.enable = true;
    udisks2.enable = true;
    gvfs.enable = true;
    upower.enable = true;
  };
}
