# Gaming configuration - Steam, Proton, GameMode
{ pkgs, lib, ... }: let
  # Create a wrapper script that sets NVIDIA PRIME offload environment variables
  # Games launched by Steam will inherit these variables and use the dGPU
  steamNvidiaWrapper = pkgs.writeShellScriptBin "steam-nvidia" ''
    # NVIDIA PRIME offload environment variables
    # These are inherited by all child processes (games)
    export __NV_PRIME_RENDER_OFFLOAD=1
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export __VK_LAYER_NV_optimus=NVIDIA_only
    
    # Launch Steam (games will inherit the above variables)
    exec ${lib.getExe pkgs.steam} "$@"
  '';

  # Desktop entry that overrides the default Steam entry
  # This ensures Steam launched from the application menu uses the NVIDIA wrapper
  steamDesktopEntry = pkgs.makeDesktopItem {
    name = "steam";
    desktopName = "Steam";
    exec = "${lib.getExe steamNvidiaWrapper} %U";
    icon = "steam";
    comment = "NVIDIA PRIME offload enabled for all games";
    categories = [ "Game" ];
    mimeTypes = [ "x-scheme-handler/steam" ];
    startupNotify = true;
  };
in {
  # Steam with NVIDIA PRIME offload wrapper
  # This ensures all games (native and Proton) run on NVIDIA dGPU
  programs.steam = {
    enable = true;
    # Open ports for Steam Remote Play
    remotePlay.openFirewall = true;
    # Open ports for Steam Local Network Game Transfers
    localNetworkGameTransfers.openFirewall = true;
    # Use Gamescope compositor for Steam
    gamescopeSession.enable = true;
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

  # System packages - Steam wrapper and gaming tools
  environment.systemPackages = with pkgs; [
    # Steam NVIDIA wrapper and desktop entry
    steamNvidiaWrapper
    steamDesktopEntry

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

