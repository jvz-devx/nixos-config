# NVIDIA configuration - drivers, PRIME, modesetting
{ config, pkgs, ... }: {
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

    # Power management (experimental)
    powerManagement = {
      enable = true;
      # Fine-grained power management (Turing+)
      finegrained = false;  # Set to true for better battery, but may cause issues
    };

    # Use open source kernel module (not nouveau, NVIDIA's open kernel module)
    # Only for Turing+ (RTX 20xx, 30xx, 40xx)
    # Keeping false for stability - open module is still experimental
    open = false;

    # NVIDIA settings GUI
    nvidiaSettings = true;

    # Driver version
    # Using stable for better reliability
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # package = config.boot.kernelPackages.nvidiaPackages.beta;

    # PRIME configuration for hybrid graphics (MUX switch systems)
    # NOTE: This laptop has a hardware MUX switch that can completely disable one GPU
    # 
    # HYBRID MODE (iGPU active): Use PRIME offload configuration below
    # DGPU MODE (iGPU disabled): Comment out entire prime section - NVIDIA works as single GPU
    #
    # CURRENTLY CONFIGURED FOR: dGPU-only mode (no PRIME)
    # 
    # To enable hybrid mode with PRIME offload, uncomment the prime block below:
    #
    # prime = {
    #   # Offload mode - iGPU by default, dGPU on demand
    #   offload = {
    #     enable = true;
    #     enableOffloadCmd = true;  # Adds `nvidia-offload` command
    #   };
    #
    #   # Bus IDs verified with: lspci | grep -E 'VGA|3D'
    #   # Intel iGPU: 00:02.0 → PCI:0:2:0
    #   # NVIDIA RTX 4080: 01:00.0 → PCI:1:0:0
    #   intelBusId = "PCI:0:2:0";   # Intel iGPU bus ID
    #   nvidiaBusId = "PCI:1:0:0";  # NVIDIA RTX 4080 bus ID
    # };
  };

  # Environment variables for X11/NVIDIA in dGPU mode
  # NOTE: These are optimized for X11 with NVIDIA as primary GPU
  # If you switch to hybrid mode with Wayland, you may need to adjust these
  environment.sessionVariables = {
    # NVIDIA-specific variables
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    
    # X11-specific (remove Wayland-specific vars that can cause issues)
    # NIXOS_OZONE_WL = "1";  # Disabled in X11 mode
    # GBM_BACKEND = "nvidia-drm";  # Only needed for Wayland
    # WLR_NO_HARDWARE_CURSORS = "1";  # Only for Wayland compositors
  };
}

