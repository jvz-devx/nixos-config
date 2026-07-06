{
  lib,
  stdenvNoCC,
  fetchurl,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr";
  version = "0.5.9";

  src = fetchurl {
    url = "https://github.com/ogulcancelik/herdr/releases/download/v${finalAttrs.version}/herdr-linux-x86_64";
    hash = "sha256-E/7B0cqoL6OSVBbXNJdsk8eoTVqHEmrzGQkKOBed524=";
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    install -Dm755 $src $out/bin/herdr

    runHook postInstall
  '';

  meta = {
    description = "Agent multiplexer that lives in your terminal";
    homepage = "https://herdr.dev";
    license = lib.licenses.agpl3Only;
    mainProgram = "herdr";
    platforms = ["x86_64-linux"];
  };
})
