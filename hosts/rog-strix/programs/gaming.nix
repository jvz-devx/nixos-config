# Gaming configuration - Steam, Proton, GameMode
{ pkgs, lib, ... }: {
  # NOTE: MUX switch configuration
  # This laptop has a hardware MUX switch. When in dGPU mode, the NVIDIA GPU
  # is the only GPU and no PRIME offload is needed. Steam and games will
  # automatically use the NVIDIA GPU.
  #
  # If you switch back to hybrid mode (iGPU active), you'll need to:
  # 1. Enable PRIME offload in nvidia.nix
  # 2. Uncomment the Steam NVIDIA wrapper below

  # Steam configuration
  programs.steam = {
    enable = true;
    # Open ports for Steam Remote Play
    remotePlay.openFirewall = true;
    # Open ports for Steam Local Network Game Transfers
    localNetworkGameTransfers.openFirewall = true;
    # DISABLED: Gamescope session adds input lag despite good frametimes
    # Gamescope is a compositor that can cause input lag even with smooth frametimes
    # Disable it and let KWin handle compositor bypass for better responsiveness
    gamescopeSession.enable = false;
  };

  # GameMode - game performance optimizations
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 0;
      };
    };
  };

  # System packages - gaming tools
  environment.systemPackages = with pkgs; [
    # Proton/Wine
    protonup-qt        # Proton version manager
    wine               # Wine for non-Steam games
    winetricks         # Wine helper scripts
  
    # Performance overlay
    mangohud           # FPS/performance overlay
    goverlay           # MangoHud GUI configurator
  
    # Gamescope
    gamescope          # Micro-compositor for games
  
    # Controllers
    # antimicrox         # Gamepad to keyboard mapping
  ];

  # 32-bit libraries for Wine/Proton (already enabled via hardware.graphics.enable32Bit)
}

