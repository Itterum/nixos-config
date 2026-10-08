{ ... }:

{
  flake.nixosModules.pcJetBrains =
    { pkgs, ... }:
    let
      helixVim = pkgs.fetchFromGitHub {
        owner = "chtenb";
        repo = "helix.vim";
        rev = "958314b6210d93d1abd4b1bc23b06a69fd17e3e9";
        hash = "sha256-BYXknpFAX2vQpebAN4yGuve+2jpB8j1ZS1dXaq2kuI0=";
      };
    in
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

      home-manager.users.itterum.home = {
        file.".ideavimrc".text = ''
          source ${helixVim}/helix.idea.vim
        '';

        sessionPath = [
          "$HOME/.local/share/JetBrains/Toolbox/scripts"
        ];
      };
    };
}
