{ ... }:

{
  users.users.itterum = {
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];

    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
    ];
  };

  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };
}
