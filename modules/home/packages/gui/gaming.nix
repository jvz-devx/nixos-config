{
  pkgs,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    prismlauncher
    heroic # GOG/Epic Games launcher
    ludusavi # Game save backup tool
    bottles # Wine/Proton prefix manager
    # proton-ge-bin isn't installable as a package anymore (upstream placeholder
    # says to use programs.steam.extraCompatPackages instead); protonup-rs below
    # fetches the latest GE-Proton into Steam's compatibilitytools.d at activation.
    protonup-rs # CLI to manage Proton-GE/Wine-GE
    rpcs3 # PlayStation 3 emulator
    cemu # Wii U emulator
  ];

  # Automatically install Proton-GE for use in Steam
  home.activation.installProtonGE = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PATH=$PATH:${pkgs.protonup-rs}/bin

    # Install latest GE-Proton to Steam's compatibilitytools.d
    # Non-fatal: network may not be available during early boot activation
    protonup-rs -q -f || echo "ProtonGE update skipped (no network). Run 'protonup-rs -f' manually."
  '';
}
