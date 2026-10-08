{
  fetchFromGitHub,
  glib,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "gnome-shell-extension-global-menu";
  version = "20";

  src = fetchFromGitHub {
    owner = "ShiroOSL";
    repo = "global-menu-for-gnome";
    rev = "7a2d0b9fb9d140576bb7a63a616d6bb2d52a7462";
    hash = "sha256-ir727C5zmIuE8QKD7QKotJw61wyW9yDVzVE6lcN2u3Q=";
  };

  nativeBuildInputs = [ glib ];

  buildPhase = ''
    runHook preBuild
    glib-compile-schemas --strict schemas
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    extensionDir=$out/share/gnome-shell/extensions/globalmenu@ShiroOSL.github.io
    mkdir -p "$extensionDir"
    cp -r . "$extensionDir"
    runHook postInstall
  '';

  passthru.extensionUuid = "globalmenu@ShiroOSL.github.io";

  meta = {
    description = "macOS-style global menu bar for GNOME Shell";
    homepage = "https://github.com/ShiroOSL/global-menu-for-gnome";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
  };
}
