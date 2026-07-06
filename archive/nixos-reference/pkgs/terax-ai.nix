{
  lib,
  stdenvNoCC,
  appimageTools,
  fetchurl,
  makeWrapper,
}: let
  pname = "terax";
  version = "0.6.0";
  src = fetchurl {
    url = "https://github.com/crynta/terax-ai/releases/download/v${version}/Terax_${version}_amd64.AppImage";
    hash = "sha256-PTJt8ebAGJEJxth08ctkX2qG6cZ4GEIKUTIWKLuuSL0=";
  };
  appimage = appimageTools.wrapType2 {
    inherit pname version src;
  };
  appimageContents = appimageTools.extractType2 {
    inherit pname version src;
  };
in
  stdenvNoCC.mkDerivation {
    inherit pname version;

    src = appimage;
    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      mkdir -p "$out"
      cp -r bin "$out/bin"

      mkdir -p "$out/share/icons"
      cp -r ${appimageContents}/usr/share/icons/* "$out/share/icons/" 2>/dev/null || true

      desktop_file=$(find ${appimageContents} -name '*.desktop' | head -n 1)
      if [ -n "$desktop_file" ]; then
        desktop_name=$(basename "$desktop_file")
        install -m 444 -D "$desktop_file" "$out/share/applications/$desktop_name"
        substituteInPlace "$out/share/applications/$desktop_name" \
          --replace-warn 'Exec=AppRun' 'Exec=terax-ai' \
          --replace-warn 'Exec=AppRun --no-sandbox' 'Exec=terax-ai'
      fi

      wrapProgram "$out/bin/terax" \
        --add-flags "--no-sandbox"

      runHook postInstall
    '';

    meta = {
      description = "Agentic development environment";
      homepage = "https://github.com/crynta/terax-ai";
      license = lib.licenses.unfree;
      mainProgram = "terax";
      platforms = ["x86_64-linux"];
    };
  }
