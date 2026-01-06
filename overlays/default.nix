# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs final.pkgs;

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    discord = prev.discord.override {
      withOpenASAR = true;
      withVencord = true;
    };

    # Use Vesktop from nixpkgs-master to get the latest version (1.6.3+)
    # We override it to fix a permission error (EACCES) during the build phase
    # where electron-builder tries to modify a read-only electron binary.
    vesktop = let
      pkgs-master = import inputs.nixpkgs-master {
        inherit (final) system;
        config.allowUnfree = true;
      };
    in
      pkgs-master.vesktop.overrideAttrs (old: {
        preBuild =
          (old.preBuild or "")
          + ''
            cp -r ${pkgs-master.electron.dist} ./electron-dist
            chmod -R u+w ./electron-dist
          '';
        buildPhase =
          builtins.replaceStrings
          ["-c.electronDist=${pkgs-master.electron.dist}"]
          ["-c.electronDist=./electron-dist"]
          old.buildPhase;
      });
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
