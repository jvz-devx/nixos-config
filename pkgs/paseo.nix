{
  lib,
  stdenvNoCC,
  appimageTools,
  makeWrapper,
  fetchurl,
}:
let
  pname = "paseo";
  version = "0.1.58";
  src = fetchurl {
    url = "https://github.com/getpaseo/paseo/releases/download/v${version}/Paseo-${version}-x86_64.AppImage";
    hash = "sha256-We+FiCNk4TP8++COJ4rxaZuJozIomiqB8Ia4mcy7Zp0=";
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
  nativeBuildInputs = [ makeWrapper ];

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
        --replace-warn 'Exec=AppRun' 'Exec=paseo' \
        --replace-warn 'Exec=AppRun --no-sandbox' 'Exec=paseo'
    fi

    runHook postInstall
  '';

  meta = {
    description = "Paseo AI coding gateway desktop app";
    license = lib.licenses.unfree;
    mainProgram = "paseo";
    platforms = [ "x86_64-linux" ];
  };
}
