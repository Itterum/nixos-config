{
  config,
  lib,
  ...
}:

{
  home.activation.installNiriConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.xdg.configHome}/niri"
    run install -m 0644 "${../../../../home/itterum/files/niri/config.kdl}" "${config.xdg.configHome}/niri/config.kdl"
  '';
}
