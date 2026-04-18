# Cloudflare `cf` CLI (technical preview)
#
# Upstream ships on npm with its six runtime deps declared but NOT bundled —
# `cf-dist/index.js` still does `import yargs from "yargs"` etc. So we can't
# just unpack the tarball; we need a resolved node_modules tree.
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
  version = "0.0.5";

  src = ./.;

  npmDepsHash = "sha256-dCcxfUEPZhdE4/mzT1D+vz0z1fSBcZl2lXT1Iid/NiQ=";

  dontNpmBuild = true;

  nativeBuildInputs = [makeWrapper];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/node_modules
    cp -R node_modules/cf $out/lib/node_modules/cf
    cp -R node_modules/cf/node_modules $out/lib/node_modules/cf/node_modules 2>/dev/null || true

    # Hoisted deps live at the top of node_modules — ship the whole tree so
    # resolution works regardless of how npm arranged it.
    mkdir -p $out/lib/cf-runtime
    cp -R node_modules $out/lib/cf-runtime/node_modules

    # Wrap cf so that CLOUDFLARE_API_TOKEN is sourced from sops-nix at
    # invocation time. Works in both interactive and non-interactive shells
    # (e.g. scripts, agent subprocesses) — unlike a zsh function.
    mkdir -p $out/bin
    makeWrapper ${lib.getExe nodejs} $out/bin/cf \
      --add-flags "$out/lib/cf-runtime/node_modules/cf/bin/cf" \
      --run '[ -z "''${CLOUDFLARE_API_TOKEN:-}" ] && [ -r /run/secrets/cloudflare_api_token ] && export CLOUDFLARE_API_TOKEN="$(cat /run/secrets/cloudflare_api_token)" || true'

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
