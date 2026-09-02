{ ... }:

{
  services.kanata = {
    enable = true;
    keyboards.internalKeyboard = {
      devices = [
        # Replace these paths with the appropriate devices for each host.
        # Use `ls /dev/input/by-path/` to discover keyboard devices.
        "/dev/input/by-path/pci-0000:0b:00.3-usb-0:3.1:1.0-event-kbd"
        "/dev/input/by-path/pci-0000:0b:00.3-usbv2-0:3.1:1.0-event-kbd"
      ];
      extraDefCfg = "process-unmapped-keys yes";
      config = ''
        (defsrc
          ralt w a s d h j k l
        )

        (defalias
          nav (layer-while-held nav)
        )

        (deflayer base
          @nav w a s d h j k l
        )

        (deflayer nav
          _ up left down right left down up right
        )
      '';
    };
  };
}
