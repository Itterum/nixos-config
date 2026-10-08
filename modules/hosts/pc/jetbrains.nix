{ ... }:

{
  flake.nixosModules.pcJetBrains =
    { pkgs, ... }:
    {
      programs.nix-ld.libraries = with pkgs; [
        alsa-lib
        cups
        dbus
        fontconfig
        freetype
        glib
        gtk3
        libx11
        libxcomposite
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxi
        libxinerama
        libxkbcommon
        libxrandr
        libxrender
        libxtst
        libxcb
        mesa
        nspr
        nss
        wayland
        zlib
      ];

      home-manager.users.itterum.home.sessionPath = [
        "$HOME/.local/share/JetBrains/Toolbox/scripts"
      ];
    };
}
