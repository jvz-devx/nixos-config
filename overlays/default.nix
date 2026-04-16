# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: let
    rustOverlay = inputs.rust-overlay.overlays.default final prev;
    pkgs-unstable = import inputs.nixpkgs {
      system = final.system;
      config.allowUnfree = true;
    };
  in {
    # Rust toolchain pinned to 1.93
    inherit (rustOverlay) rust-bin;
    discord = prev.discord.override {
      withOpenASAR = true;
      withVencord = true;
    };

    # Pin opencode to nixpkgs-master because the main nixpkgs input lagged on
    # 1.0.210, which did not expose the newer auth flow we needed for Codex.
    # Using the packaged nixpkgs-master derivation also preserves its Bun
    # compatibility patch, unlike the raw upstream flake package.
    opencode =
      (import inputs.nixpkgs-master {
        system = final.system;
        config.allowUnfree = true;
      }).opencode;

    # Keep Vesktop on the packaged nixpkgs-master build.
    # Our older local override started failing once Electron's layout changed,
    # so we intentionally prefer the upstream nixpkgs package as-is.
    vesktop = let
      pkgs-master = import inputs.nixpkgs-master {
        inherit (final) system;
        config.allowUnfree = true;
      };
    in
      pkgs-master.vesktop;
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
