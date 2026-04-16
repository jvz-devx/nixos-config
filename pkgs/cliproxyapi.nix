{
  lib,
  fetchurl,
  stdenvNoCC,
}: let
  version = "6.9.24";
  releases = {
    x86_64-linux = {
      url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_amd64.tar.gz";
      hash = "sha256-n6UtlJS/wtYePQcLF19TDsxIaebnhXncmoKDe5bMeqE=";
    };
    aarch64-linux = {
      url = "https://github.com/router-for-me/CLIProxyAPI/releases/download/v${version}/CLIProxyAPI_${version}_linux_arm64.tar.gz";
      hash = "sha256-8vzc6Ks2YO+cU3JfOx8KW2zI2kLPdptkpkJLc5BpDOE=";
    };
  };
  release =
    releases.${stdenvNoCC.hostPlatform.system}
    or (throw "cliproxyapi is not packaged for ${stdenvNoCC.hostPlatform.system}");
in
  stdenvNoCC.mkDerivation {
    pname = "cliproxyapi";
    inherit version;

    src = fetchurl release;

    sourceRoot = ".";

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/share/doc/cliproxyapi
      install -m755 cli-proxy-api $out/bin/cliproxyapi-bin
      cat > $out/bin/cliproxyapi <<'EOF'
      #!__SHELL__
      set -eu

      home_dir="''${HOME:-}"
      if [ -z "$home_dir" ] || [ "$home_dir" = "/homeless-shelter" ]; then
        home_dir="$(getent passwd "$(id -un)" | cut -d: -f6)"
      fi

      for arg in "$@"; do
        if [ "$arg" = "--config" ]; then
          exec "__BIN__" "$@"
        fi
      done

      exec "__BIN__" --config "$home_dir/.cli-proxy-api/config.yaml" "$@"
      EOF
      substituteInPlace $out/bin/cliproxyapi \
        --replace-fail __SHELL__ ${stdenvNoCC.shell} \
        --replace-fail __BIN__ $out/bin/cliproxyapi-bin
      chmod +x $out/bin/cliproxyapi
      install -m644 config.example.yaml $out/share/doc/cliproxyapi/config.example.yaml
      install -m644 README.md $out/share/doc/cliproxyapi/README.md
      install -m644 LICENSE $out/share/doc/cliproxyapi/LICENSE

      runHook postInstall
    '';

    meta = {
      description = "Proxy for OpenAI, Gemini, Claude, and Codex compatible APIs";
      homepage = "https://github.com/router-for-me/CLIProxyAPI";
      license = lib.licenses.mit;
      platforms = builtins.attrNames releases;
      mainProgram = "cliproxyapi";
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
    };
  }
