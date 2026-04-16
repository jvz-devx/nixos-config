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
    # Flatpak packages for gaming
    # TODO: DLSS-Updater is currently broken on Linux (v3.5.2 and below)
    # See: https://github.com/Recol/DLSS-Updater/issues/122
    # Wait for a new version before re-enabling.
    # myConfig.services.flatpak.bundles = [
    #   "https://github.com/Recol/DLSS-Updater/releases/download/V3.5.1/DLSS_Updater-3.5.1.flatpak"
    # ];

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
          softrealtime = "auto"; # SCHED_ISO on CachyOS — near-realtime priority
          ioprio = 0; # Highest IO priority
          inhibit_screensaver = 1;
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          nv_powermizer_mode = 1; # Maximum GPU performance during gaming
        };
        custom = {
          start = "qdbus6 org.kde.KWin /Compositor suspend";
          end = "qdbus6 org.kde.KWin /Compositor resume";
        };
      };
    };

    # Gaming-related kernel tweaks
    boot.extraModprobeConfig = lib.mkAfter ''
      options usbhid mousepoll=1
    '';

    boot.kernelParams = [
      "tsc=reliable"
      "clocksource=tsc"
    ];

    boot.kernel.sysctl = {
      "vm.compaction_proactiveness" = 0; # Reduce memory compaction stalls
      "vm.min_free_kbytes" = 1048576; # 1GB reserve to avoid allocation stalls
      "kernel.split_lock_mitigate" = 0; # Prevent micro-stutters
    };

    # Allow game processes to use high priority scheduling
    security.pam.loginLimits = [
      {
        domain = "*";
        type = "-";
        item = "nice";
        value = "-20";
      }
      {
        domain = "*";
        type = "soft";
        item = "rtprio";
        value = "95";
      }
    ];

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
