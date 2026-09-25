# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  modifications = final: prev: {
    # Pin claude-code ahead of nixpkgs.
    #
    # Why: claude-code ships several releases a week, nixpkgs lags behind (the
    # pinned nixpkgs had 2.1.220 when 2.1.280 was current). The nixpkgs
    # derivation takes its version + per-platform binary checksums from a
    # `manifest` argument that defaults to Anthropic's release manifest vendored
    # into nixpkgs, so overriding that one argument is enough to move versions -
    # no derivation copy, no hash guessing.
    #
    # To bump:
    #   V=$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)
    #   curl -fsSL "https://downloads.claude.ai/claude-code-releases/$V/manifest.json" \
    #     -o pkgs/claude-code/manifest.json
    #   git add pkgs/claude-code/manifest.json   # untracked files are invisible to flakes
    #   nix eval .#darwinConfigurations.macbook-pro.pkgs.claude-code.version
    #
    # Drop this override once nixpkgs ships a version >= the one pinned here.
    claude-code = prev.claude-code.override {
      manifest = final.lib.importJSON ../pkgs/claude-code/manifest.json;
    };
  };

  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable' - useful for packages that break on unstable
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
