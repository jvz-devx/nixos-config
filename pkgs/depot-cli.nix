# Depot CLI - fast Docker image builder
# https://depot.dev
{
  lib,
  fetchzip,
  stdenv,
  autoPatchelfHook,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "depot-cli";
  version = "2.101.38";

  src = fetchzip {
    url = "https://github.com/depot/cli/releases/download/v${finalAttrs.version}/depot_${finalAttrs.version}_linux_amd64.tar.gz";
    hash = "sha256-Ll2gg1Ipac+UfMzdTnu2bV81rgW8vEUF3uW7ReIqr3s=";
    stripRoot = false;
  };

  nativeBuildInputs = [autoPatchelfHook];

  installPhase = ''
    mkdir -p $out/bin
    cp bin/depot $out/bin/depot
    chmod +x $out/bin/depot
  '';

  meta = {
    description = "Depot CLI - fast Docker image builder";
    homepage = "https://depot.dev";
    license = lib.licenses.unfree;
    platforms = ["x86_64-linux"];
  };
})
