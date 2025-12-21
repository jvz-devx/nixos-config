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
    open = false;  # TODO: Set to true if you want to try NVIDIA's open kernel module

    # NVIDIA settings GUI
    nvidiaSettings = true;

    # Driver version
    # Use stable driver unless you need beta features
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    # package = config.boot.kernelPackages.nvidiaPackages.beta;

    # PRIME configuration for hybrid graphics
    prime = {
      # Offload mode - iGPU by default, dGPU on demand
      offload = {
        enable = true;
        enableOffloadCmd = true;  # Adds `nvidia-offload` command
      };

      # TODO: Get your bus IDs with: nix-shell -p pciutils --run "lspci | grep -E 'VGA|3D'"
      # Example output: 00:02.0 VGA ... Intel
      #                 01:00.0 3D ... NVIDIA
      # Convert to: "PCI:0:2:0" and "PCI:1:0:0"
      intelBusId = "PCI:0:2:0";   # Intel iGPU bus ID
      nvidiaBusId = "PCI:1:0:0";  # TODO: Replace with your NVIDIA dGPU bus ID

      # Alternative: Sync mode (always use dGPU, worse battery)
      # sync.enable = true;

      # Alternative: Reverse sync (dGPU renders to iGPU, experimental)
      # reverseSync.enable = true;
    };
  };

  # Environment variables for Wayland/NVIDIA
  environment.sessionVariables = {
    # Hint to Electron apps to use Wayland
    NIXOS_OZONE_WL = "1";
    # NVIDIA-specific Wayland hints
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    # Workaround for some apps
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}

