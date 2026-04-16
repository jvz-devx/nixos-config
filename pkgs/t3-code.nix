{
  lib,
  stdenvNoCC,
  appimageTools,
  fetchurl,
  makeWrapper,
}: let
  version = "0.0.15";
  src = fetchurl {
    url = "https://github.com/pingdotgg/t3code/releases/download/v${version}/T3-Code-${version}-x86_64.AppImage";
    hash = "sha256-Z8y7SWH55+ZC7cRpgo0cdG273rbDiFS3pXQt3up7sDg=";
  };
  appimage = appimageTools.wrapType2 {
    pname = "t3-code";
    inherit version src;
  };
  appimageContents = appimageTools.extractType2 {
    pname = "t3-code";
    inherit version src;
  };
in
  stdenvNoCC.mkDerivation {
    pname = "t3-code";
    inherit version;

    src = appimage;

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/
      cp -r bin $out/bin

      mkdir -p $out/share/icons
      cp -r ${appimageContents}/usr/share/icons/* $out/share/icons/ 2>/dev/null || true

      if [ -f ${appimageContents}/t3-code.desktop ]; then
        install -m 444 -D ${appimageContents}/t3-code.desktop $out/share/applications/t3-code.desktop
        substituteInPlace $out/share/applications/t3-code.desktop \
          --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=t3-code' || true
      fi

      wrapProgram $out/bin/t3-code \
        --add-flags "--no-sandbox"

      runHook postInstall
    '';

    meta = {
      description = "T3 Code - GUI for AI coding agents";
      homepage = "https://t3.codes";
      license = lib.licenses.mit;
      mainProgram = "t3-code";
      platforms = ["x86_64-linux"];
    };
  }
