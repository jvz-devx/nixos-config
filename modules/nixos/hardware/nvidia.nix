# Unified NVIDIA configuration for desktop and laptop
# Supports both desktop (single GPU) and laptop (PRIME/hybrid) configurations
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.myConfig.hardware.nvidia;
  # Use myConfig.hardware.nvidia.mode if available, fallback to hardware.gpuMode for backward compatibility
  isLaptop = cfg.isLaptop or false;
  gpuMode =
    cfg.mode or config.hardware.gpuMode or (
      if isLaptop
      then "dedicated"
      else "desktop"
    );
  isDedicated = gpuMode == "dedicated";
  isHybrid = gpuMode == "hybrid";
  isIntegrated = gpuMode == "integrated";
  isDesktop = gpuMode == "desktop" || (!isLaptop && !isDedicated && !isHybrid && !isIntegrated);
in {
  options.myConfig.hardware.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU support";
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable laptop-specific features (PRIME/Offload support)";
    };
    mode = lib.mkOption {
      type = lib.types.enum ["dedicated" "hybrid" "integrated" "desktop"];
      default =
        if cfg.isLaptop or false
        then "dedicated"
        else "desktop";
      description = ''
        GPU mode selection:
        - "dedicated"   : dGPU only (laptop: max performance, poor battery)
        - "hybrid"      : Reverse sync (laptop: good performance, okay battery)
        - "integrated"  : iGPU only (laptop: best battery, lowest performance)
        - "desktop"     : Desktop mode (single NVIDIA GPU, no PRIME)
      '';
    };
    driverBranch = lib.mkOption {
      type = lib.types.enum ["stable" "beta" "latest" "production"];
      default =
        if cfg.isLaptop or false
        then "stable"
        else "beta";
      description = "NVIDIA driver branch to use (stable, beta, latest, production)";
    };
  };

  config = lib.mkIf cfg.enable {
    # Enable OpenGL/Vulkan graphics
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs;
        if isIntegrated
        then [
          intel-media-driver # Intel VA-API (iHD)
          libva-utils
        ]
        else [
          nvidia-vaapi-driver
          libva-utils
        ];
    };

    # NVIDIA driver (disabled in integrated mode for laptops)
    services.xserver.videoDrivers = lib.mkIf (!isIntegrated) ["nvidia"];

    hardware.nvidia = lib.mkIf (!isIntegrated) {
      # Modesetting is required for Wayland
      modesetting.enable = true;

      # Power management
      powerManagement = {
        enable = true;
        # Fine-grained power management for laptops in integrated mode (Turing+)
        finegrained = isIntegrated && isLaptop;
      };

      # Use open source kernel module (NVIDIA's open kernel module)
      # Only for Turing+ (RTX 20xx, 30xx, 40xx)
      open = false;

      # NVIDIA settings GUI
      nvidiaSettings = true;

      # Driver version
      package = config.boot.kernelPackages.nvidiaPackages.${cfg.driverBranch};

      # PRIME Configuration - Only for laptop in hybrid mode
      prime = lib.mkIf (isLaptop && isHybrid) {
        # Reverse sync - NVIDIA always renders, Intel outputs
        reverseSync.enable = true;

        # Bus IDs verified with: lspci | grep -E 'VGA|3D'
        intelBusId = "PCI:0:2:0";
        nvidiaBusId = "PCI:1:0:0";
      };
    };

    # Early KMS - load NVIDIA modules early in boot (desktop and laptop non-integrated modes)
    boot.initrd.kernelModules = lib.mkIf (!isIntegrated) [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ];

    # Kernel parameters for NVIDIA
    boot.kernelParams = lib.mkIf (!isIntegrated) [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
    ];

    # Environment variables for Wayland + NVIDIA
    environment.sessionVariables = lib.mkMerge [
      # Wayland variables (all modes)
      {
        NIXOS_OZONE_WL = "1"; # Electron apps use Wayland
      }

      # NVIDIA-specific variables (all modes except integrated)
      (lib.mkIf (!isIntegrated) {
        __GLX_VENDOR_LIBRARY_NAME = "nvidia";
        LIBVA_DRIVER_NAME = "nvidia";
        NVD_BACKEND = "direct";
        GBM_BACKEND = "nvidia-drm";
        # Fix for Qt6/KDE6 Wayland EGL decoration context crash
        # Prevents "QWaylandGLContext: Failed to create decorations EGLContext" error
        QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      })
    ];
  };
}
