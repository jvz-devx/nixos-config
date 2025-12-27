# Gaming configuration - Steam, Proton, GameMode
# Shared gaming module for all hosts
{ config, lib, pkgs, ... }: {
  options.myConfig.programs.gaming.enable = lib.mkEnableOption "Gaming support (Steam, Proton, GameMode)";

  config = lib.mkIf config.myConfig.programs.gaming.enable {
    # Steam configuration
    programs.steam = {
      enable = true;
      # Open ports for Steam Remote Play
      remotePlay.openFirewall = true;
      # Open ports for Steam Local Network Game Transfers
      localNetworkGameTransfers.openFirewall = true;
      # Gamescope session (can add input lag, disabled by default)
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
      protontricks       # Proton helper scripts
      wine               # Wine for non-Steam games
      winetricks         # Wine helper scripts

      # Performance overlay
      mangohud           # FPS/performance overlay
      goverlay           # MangoHud GUI configurator

      # Gamescope
      gamescope          # Micro-compositor for games
    ];
  };
}


