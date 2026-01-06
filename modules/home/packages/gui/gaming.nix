{ pkgs, inputs, lib, ... }: {
  home.packages = with pkgs; [
    prismlauncher
    heroic         # GOG/Epic Games launcher
    ludusavi       # Game save backup tool
    bottles        # Wine/Proton prefix manager
    inputs.chaotic.packages.${pkgs.stdenv.hostPlatform.system}.proton-ge-custom # Custom Proton builds
    protonup-rs    # CLI to manage Proton-GE/Wine-GE
    rpcs3          # PlayStation 3 emulator
    cemu           # Wii U emulator
  ];

  # Automatically install Proton-GE for use in Steam
  home.activation.installProtonGE = lib.hm.dag.entryAfter ["writeBoundary"] ''
    PATH=$PATH:${pkgs.protonup-rs}/bin
    
    # Install latest GE-Proton to Steam's compatibilitytools.d
    protonup-rs -q -f
  '';
}

