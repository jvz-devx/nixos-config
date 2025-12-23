# NVIDIA configuration for laptop with PRIME (Intel + NVIDIA)
# This file automatically configures based on hardware.gpuMode setting
{ config, pkgs, lib, ... }:

let
  mode = config.hardware.gpuMode;
  isDedicated = mode == "dedicated";
  isHybrid = mode == "hybrid";
  isIntegrated = mode == "integrated";
in {
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA driver (disabled in integrated mode)
  services.xserver.videoDrivers = lib.mkIf (!isIntegrated) ["nvidia"];

  hardware.nvidia = lib.mkIf (!isIntegrated) {
    # Modesetting is required for Wayland
    modesetting.enable = true;

    # Power management
    powerManagement = {
      enable = true;
      # Fine-grained power management (Turing+)
      finegrained = isIntegrated;
    };

    # Use open source kernel module (NVIDIA's open kernel module)
    open = false;

    # NVIDIA settings GUI
    nvidiaSettings = true;

    # Driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # PRIME Configuration - Automatic based on mode
    prime = lib.mkIf isHybrid {
      # Reverse sync - NVIDIA always renders, Intel outputs
      reverseSync.enable = true;

      # Bus IDs verified with: lspci | grep -E 'VGA|3D'
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  # Environment variables - automatic based on mode
  environment.sessionVariables = lib.mkMerge [
    # Wayland variables (all modes)
    {
      NIXOS_OZONE_WL = "1";
    }

    # NVIDIA-specific variables (dedicated and hybrid modes)
    (lib.mkIf (!isIntegrated) {
      __GLX_VENDOR_LIBRARY_NAME = "nvidia";
      LIBVA_DRIVER_NAME = "nvidia";
      GBM_BACKEND = "nvidia-drm";
      WLR_NO_HARDWARE_CURSORS = "1";
    })
  ];
}


