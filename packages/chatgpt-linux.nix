{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  at-spi2-atk,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libgbm,
  libGL,
  libnotify,
  libusb1,
  libxkbcommon,
  libx11,
  libxcb,
  libxcomposite,
  libxdamage,
  libxext,
  libxfixes,
  libxrandr,
  nspr,
  nss,
  pango,
  systemd,
  vulkan-loader,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "chatgpt-linux";
  version = "26.908.70816";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/latest/chatgpt_amd64.deb";
    hash = "sha256-EO0MGogLmXXR8YW/eRGn9RTga5hjzU7ZVh1ABjYXyFQ=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libgbm
    libGL
    libnotify
    libusb1
    libxkbcommon
    nspr
    nss
    pango
    vulkan-loader
    libx11
    libxcb
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
  ];

  runtimeDependencies = [ (lib.getLib systemd) ];

  # The archive carries both glibc and musl prebuilds. Only the glibc variants
  # are loadable on NixOS; keep the unused musl alternatives untouched.
  autoPatchelfIgnoreMissingDeps = [
    "libc.musl-x86_64.so.1"
    "libQt5Core.so.5"
    "libQt5Gui.so.5"
    "libQt5Widgets.so.5"
    "libQt6Core.so.6"
    "libQt6Gui.so.6"
    "libQt6Widgets.so.6"
  ];

  installPhase = ''
    runHook preInstall

    cp -r usr "$out"
    rm -rf "$out/share/lintian"

    rm "$out/bin/chatgpt"
    makeWrapper "$out/lib/chatgpt/ChatGPT" "$out/bin/chatgpt" \
      --add-flags '--ozone-platform-hint=auto'

    runHook postInstall
  '';

  meta = {
    description = "Official ChatGPT desktop app for Linux with Codex";
    homepage = "https://learn.chatgpt.com/docs/linux/linux-app";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "chatgpt";
    platforms = [ "x86_64-linux" ];
  };
})
