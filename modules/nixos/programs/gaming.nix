# Gaming configuration - Steam, Proton, GameMode
# Shared gaming module for all hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.programs.gaming = {
    enable = lib.mkEnableOption "Gaming support (Steam, Proton, GameMode)";
    sunshine.enable = lib.mkEnableOption "Sunshine Game Stream";
  };

  config = lib.mkIf config.myConfig.programs.gaming.enable {
    # Steam configuration
    programs.steam = {
      enable = true;
      # Use a wrapped Steam package that automatically enables MangoHud
      package = pkgs.steam.override {
        extraEnv = {
          MANGOHUD = "1";
        };
      };
      # Open ports for Steam Remote Play
      remotePlay.openFirewall = true;
      # Open ports for Steam Local Network Game Transfers
      localNetworkGameTransfers.openFirewall = true;
      # Gamescope session (can add input lag, disabled by default)
      gamescopeSession.enable = false;
    };

    # Sunshine Game Stream
    services.sunshine = lib.mkIf config.myConfig.programs.gaming.sunshine.enable {
      enable = true;
      autoStart = true;
      openFirewall = true;
      capSysAdmin = true; # Required for KMS capture
    };

    # Avahi for network discovery
    services.avahi = lib.mkIf config.myConfig.programs.gaming.sunshine.enable {
      enable = true;
      nssmdns4 = true;
      publish = {
        enable = true;
        userServices = true;
      };
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
      bottles # Wine/Proton prefix manager
      protonup-qt # Proton version manager
      protontricks # Proton helper scripts
      wine # Wine for non-Steam games
      winetricks # Wine helper scripts
      wine-wayland # Better Wine for Wayland/KDE

      # Performance overlay
      mangohud # FPS/performance overlay
      goverlay # MangoHud GUI configurator

      # Gamescope
      gamescope # Micro-compositor for games

      # Game Streaming
      moonlight-qt # Moonlight client

      # Emulators
      dolphin-emu # GameCube/Wii emulator
    ];

    # Udev rules for GameCube controllers (dolphin-emu)
    services.udev.packages = with pkgs; [
      dolphin-emu
    ];

    # Optional: GCC to USB adapter overclocking for improved polling rates
    # Uncomment to enable gcadapter-oc-kmod kernel module
    # boot.extraModulePackages = [
    #   config.boot.kernelPackages.gcadapter-oc-kmod
    # ];
    # boot.kernelModules = [
    #   "gcadapter_oc"
    # ];
  };
}
