{ pkgs, inputs, ... }: {
  home.packages = with pkgs; [
    prismlauncher
    heroic         # GOG/Epic Games launcher
    ludusavi       # Game save backup tool
    inputs.chaotic.packages.${pkgs.stdenv.hostPlatform.system}.proton-ge-custom # Custom Proton builds
    rpcs3          # PlayStation 3 emulator
    cemu           # Wii U emulator
  ];
}

