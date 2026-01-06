# Boot configuration for laptops
# Includes custom kernel, hibernation, and GPU-specific kernel params
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Use myConfig.hardware.nvidia.mode if available, fallback to hardware.gpuMode for backward compatibility
  gpuMode = config.myConfig.hardware.nvidia.mode or config.hardware.gpuMode or "desktop";
  isDedicated = gpuMode == "dedicated";
  isHybrid = gpuMode == "hybrid";
  isIntegrated = gpuMode == "integrated";
  isDesktop = gpuMode == "desktop" || (!isDedicated && !isHybrid && !isIntegrated);
in {
  options.myConfig.system.boot.laptop = {
    enable = lib.mkEnableOption "Laptop boot configuration (custom kernel, hibernation, GPU params)";
    resumeDevice = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Resume device for hibernation (e.g., /dev/disk/by-uuid/...)";
    };
    kernelPackages = lib.mkOption {
      type = lib.types.anything;
      default = null;
      description = "Custom kernel packages (e.g., pkgs.linuxPackages_cachyos)";
    };
  };

  config = lib.mkIf config.myConfig.system.boot.laptop.enable {
    # Bootloader
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkDefault 3; # Allow ISO module to override
    };

    # Custom kernel packages if specified
    boot.kernelPackages =
      lib.mkIf (config.myConfig.system.boot.laptop.kernelPackages != null)
      config.myConfig.system.boot.laptop.kernelPackages;

    # Hibernation resume device if specified
    boot.resumeDevice =
      lib.mkIf (config.myConfig.system.boot.laptop.resumeDevice != null)
      config.myConfig.system.boot.laptop.resumeDevice;

    # Early KMS (Kernel Mode Setting) - load drivers early in boot
    boot.initrd.kernelModules =
      lib.optionals (!isIntegrated && !isDesktop) [
        "nvidia"
        "nvidia_modeset"
        "nvidia_uvm"
        "nvidia_drm"
      ]
      ++
      # Always load i915 for audio support, even in dedicated mode
      ["i915"];

    # Blacklist problematic kernel modules
    boot.blacklistedKernelModules =
      [
        "spd5118"
      ]
      ++
      # NOTE: We no longer blacklist i915 even in dedicated mode
      # because the Intel Audio controller depends on it for power management
      # and probe completion on Raptor Lake laptops.
      lib.optionals isDedicated [
        "xe"
      ]
      ++ lib.optionals isIntegrated [
        "nvidia"
        "nvidia_drm"
        "nvidia_modeset"
      ];

    # Kernel parameters
    boot.kernelParams =
      [
        (lib.mkIf (config.myConfig.system.boot.laptop.resumeDevice != null)
          "resume=${config.myConfig.system.boot.laptop.resumeDevice}")
        "acpi.debug_level=0"
      ]
      ++ lib.optionals (!isIntegrated && !isDesktop) [
        "nvidia-drm.modeset=1"
        "nvidia-drm.fbdev=1"
        "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
      ];
  };
}
