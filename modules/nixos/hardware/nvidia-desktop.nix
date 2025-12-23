# NVIDIA configuration for desktop PCs (no PRIME/hybrid GPU)
# Use this for systems with only NVIDIA GPU (no integrated graphics)
{ config, pkgs, lib, ... }: {
  # Enable OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # NVIDIA driver
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is required for Wayland
    modesetting.enable = true;

    # Power management (less relevant for desktops, but doesn't hurt)
    powerManagement.enable = true;

    # Use open source kernel module (not nouveau, NVIDIA's open kernel module)
    # Only for Turing+ (RTX 20xx, 30xx, 40xx)
    open = false;

    # NVIDIA settings GUI
    nvidiaSettings = true;

    # Driver version
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Early KMS - load NVIDIA modules early in boot
  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  # Kernel parameters for NVIDIA
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ];

  # Environment variables for Wayland + NVIDIA
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";  # Electron apps use Wayland
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    GBM_BACKEND = "nvidia-drm";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}


