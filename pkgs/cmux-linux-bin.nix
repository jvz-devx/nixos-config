{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  dpkg,
  perl,
  gtk4,
  fontconfig,
  freetype,
  harfbuzz,
  glib,
  libGL,
  oniguruma,
  vulkan-loader,
  stdenv,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "cmux-linux-bin";
  version = "0.1.0";

  src = fetchurl {
    url = "https://github.com/bradwilson331/cmux-linux/releases/download/${finalAttrs.version}/cmux_${finalAttrs.version}_amd64.deb";
    hash = "sha256-oh0VzluAV31g0EKGy9H6A87s8WSvbXSnoyWJuiPzJy4=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
    perl
  ];

  buildInputs = [
    gtk4
    fontconfig
    freetype
    harfbuzz
    glib
    libGL
    oniguruma
    vulkan-loader
    stdenv.cc.cc.lib
  ];

  unpackCmd = "dpkg-deb -x $src source";

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -R usr/* $out/

    substituteInPlace $out/bin/cmux-app \
      --replace-fail '/usr/bin/cmux-app.bin' "$out/bin/cmux-app.bin"

    perl -0pi -e 's/if \[ -z "\$GDK_BACKEND" \]; then\n/if [ -z "\$GTK_THEME" ]; then\n    export GTK_THEME=Adwaita\nfi\n\nif [ -z "\$GDK_DEBUG" ]; then\n    export GDK_DEBUG=gl-prefer-gl\nfi\n\nif [ -z "\$GDK_BACKEND" ]; then\n/' $out/bin/cmux-app

    runHook postInstall
  '';

  meta = {
    description = "Prebuilt cmux for Linux binaries";
    homepage = "https://github.com/bradwilson331/cmux-linux";
    license = lib.licenses.agpl3Plus;
    platforms = ["x86_64-linux"];
    mainProgram = "cmux-app";
  };
})
