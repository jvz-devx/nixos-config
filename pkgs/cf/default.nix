# Cloudflare `cf` CLI (technical preview)
#
# Strategy: a tiny wrapper package.json pulls in `cf@<version>` as its sole
# dep. `buildNpmPackage` installs that tree from the committed lockfile
# (offline, reproducible), and we expose cf's bin via makeWrapper pointing
# node at the resolved install.
#
# To bump: edit `version` + `package.json` + re-run `npm install
# --package-lock-only --ignore-scripts`, then update `npmDepsHash`
# (set to lib.fakeHash first, rebuild, copy the reported hash).
#
# Upstream: https://www.npmjs.com/package/cf
# Blog:     https://blog.cloudflare.com/cf-cli-local-explorer/
{
  lib,
  buildNpmPackage,
  nodejs,
  makeWrapper,
}:
buildNpmPackage (finalAttrs: {
  pname = "cloudflare-cf";
  version = "0.10.0";

  src = ./.;

  npmDepsHash = "sha256-RCsnL10wniHbF7VzZ9e6jNrcV34LEAYCk3D+FB3zLOg=";

  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall

    # Hoisted deps live at the top of node_modules — ship the whole tree so
    # resolution works regardless of how npm arranged it.
    mkdir -p $out/lib/cf-runtime
    cp -R node_modules $out/lib/cf-runtime/node_modules

    # Encrypt profile credentials with a key stored in the macOS Keychain.
    # Do not inject a shared API token, which would override profile selection.
    mkdir -p $out/bin
    makeWrapper ${lib.getExe nodejs} $out/bin/cf \
      --add-flags "$out/lib/cf-runtime/node_modules/cf/bin/cf" \
      --set CLOUDFLARE_AUTH_USE_KEYRING true

    runHook postInstall
  '';

  meta = {
    description = "Cloudflare CLI — unified CLI for the Cloudflare platform (technical preview)";
    homepage = "https://www.npmjs.com/package/cf";
    license = lib.licenses.mit;
    mainProgram = "cf";
    platforms = nodejs.meta.platforms;
    sourceProvenance = [lib.sourceTypes.fromSource];
  };
})
