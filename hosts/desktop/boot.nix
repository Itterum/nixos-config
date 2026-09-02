{
  boot.loader = {
    systemd-boot.enable = false;

    efi.canTouchEfiVariables = true;

    limine = {
      enable = true;
      efiSupport = true;

      secureBoot = {
        enable = true;
        autoGenerateKeys = true;
        autoEnrollKeys.enable = true;
      };

      maxGenerations = 5;

      extraEntries = ''
        /Windows 11
        protocol: efi_boot_entry
        entry: Windows Boot Manager
      '';
    };

    timeout = 15;
  };
}
