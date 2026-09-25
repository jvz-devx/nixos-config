# claude-code version pin

`manifest.json` is Anthropic's upstream release manifest, fetched verbatim from:

    https://downloads.claude.ai/claude-code-releases/<version>/manifest.json

It holds the version string and the sha256 of the prebuilt `claude` binary for
every platform. `overlays/default.nix` feeds it to nixpkgs' `claude-code`
derivation via its `manifest` argument, which pins us to whatever version this
file names - independent of how far behind the nixpkgs input is.

JSON has no comments, hence this file.

## Bumping

    V=$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)
    curl -fsSL "https://downloads.claude.ai/claude-code-releases/$V/manifest.json" \
      -o pkgs/claude-code/manifest.json
    git add pkgs/claude-code/manifest.json   # untracked files are invisible to flakes
    nix eval .#darwinConfigurations.macbook-pro.pkgs.claude-code.version
    darwin-rebuild switch --flake .#macbook-pro

Pin a specific version by substituting it for `$V` instead of using `latest`.

## Removing the pin

Once the `nixpkgs` flake input carries a version >= the one in `manifest.json`,
delete this directory and the `claude-code` entry in `overlays/default.nix`.
Check what nixpkgs currently has with:

    nix eval --impure --raw --expr \
      'let f = builtins.getFlake (toString ./.); in (import f.inputs.nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; }).claude-code.version'
