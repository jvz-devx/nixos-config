{
  lib,
  nodejs_24,
  stdenvNoCC,
  makeWrapper,
}: let
  version = "0-unstable-2026-05-22";
in
  stdenvNoCC.mkDerivation {
    pname = "svelte-autofix";
    inherit version;

    src = ./svelte-autofix.mjs;
    dontUnpack = true;

    nativeBuildInputs = [makeWrapper];

    installPhase = ''
      runHook preInstall

      install -Dm755 $src $out/libexec/svelte-autofix/svelte-autofix.mjs
      makeWrapper ${nodejs_24}/bin/node $out/bin/svelte-autofix \
        --add-flags "$out/libexec/svelte-autofix/svelte-autofix.mjs"

      runHook postInstall
    '';

    meta = {
      description = "Codex helper for running the Svelte MCP autofixer";
      homepage = "https://github.com/jvz-devx/codex-svelte-autofix-agent";
      license = lib.licenses.mit;
      mainProgram = "svelte-autofix";
      platforms = ["x86_64-linux"];
    };
  }
