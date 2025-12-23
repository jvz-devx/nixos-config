# Boot configuration for ROG Strix laptop
# Includes CachyOS kernel, hibernation, and GPU-specific kernel params
{ config, pkgs, lib, ... }:

let
  mode = config.hardware.gpuMode;
  isDedicated = mode == "dedicated";
  isHybrid = mode == "hybrid";
  isIntegrated = mode == "integrated";
in {
  # Bootloader
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      editor = false;
    };
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # CachyOS kernel (gaming-optimized with performance patches)
  boot.kernelPackages = pkgs.linuxPackages_cachyos;

  # Hibernation resume device (swap partition)
  boot.resumeDevice = "/dev/disk/by-uuid/4d48cb91-7bfa-448e-bc21-93e228ddd729";

  # Early KMS (Kernel Mode Setting) - load drivers early in boot
  boot.initrd.kernelModules =
    lib.optionals (!isIntegrated) [
      "nvidia"
      "nvidia_modeset"
      "nvidia_uvm"
      "nvidia_drm"
    ] ++
    lib.optionals (!isDedicated) [
      "i915"
    ];

  # Blacklist problematic kernel modules
  boot.blacklistedKernelModules = [
    "spd5118"
  ] ++
  lib.optionals isDedicated [
    "i915"
    "xe"
  ] ++
  lib.optionals isIntegrated [
    "nvidia"
    "nvidia_drm"
    "nvidia_modeset"
  ];

  # Kernel parameters
  boot.kernelParams = [
    "resume=/dev/disk/by-uuid/4d48cb91-7bfa-448e-bc21-93e228ddd729"
    "acpi.debug_level=0"
  ] ++
  lib.optionals (!isIntegrated) [
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1"
  ] ++
  lib.optionals isDedicated [
    "i915.modeset=0"
    "initcall_blacklist=i915_init"
  ];
}


