{ ... }:

{
  flake.nixosModules.pcStorage = {
    fileSystems."/mnt/storage" = {
      device = "/dev/disk/by-uuid/BFB4-A380";
      fsType = "exfat";
      options = [
        "nofail"
        "x-systemd.automount"
        "x-systemd.device-timeout=5s"
        "x-systemd.idle-timeout=10min"
        "uid=1000"
        "gid=100"
        "fmask=0022"
        "dmask=0022"
      ];
    };
  };
}
