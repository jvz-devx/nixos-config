# Boot configuration - systemd-boot, kernel, kernel params
{ pkgs, ... }: {
  # Bootloader
  boot.loader = {
    systemd-boot = {
      enable = true;
      configurationLimit = 10;
      editor = false;  # Disable editing boot entries for security
    };
    efi.canTouchEfiVariables = true;
    timeout = 3;
  };

  # Kernel
  # CachyOS kernel (gaming-optimized with performance patches)
  # Access through chaotic overlay (added in configuration.nix)
  # Note: linuxPackages_cachyos is already a packages set, not a kernel source
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  # Alternatives:
  # boot.kernelPackages = pkgs.linuxPackages_latest;  # Latest stable
  # boot.kernelPackages = pkgs.linuxPackages_6_12;    # Specific version

  # Hibernation resume device (swap partition)
  # Swap is configured in hardware-configuration.nix
  boot.resumeDevice = "/dev/disk/by-uuid/4d48cb91-7bfa-448e-bc21-93e228ddd729";

  # Blacklist problematic kernel modules
  # spd5118: Memory controller driver that causes resume delays on ASUS laptops
  boot.blacklistedKernelModules = [ "spd5118" ];

  # Kernel parameters
  boot.kernelParams = [
    # NVIDIA Wayland support
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"
    # Fix display overscan/underscan (prevents cut-off corners)
    "nvidia-drm.allow_fbdev=1"

    # Hibernation resume (required for hibernate to work)
    "resume=/dev/disk/by-uuid/4d48cb91-7bfa-448e-bc21-93e228ddd729"

    # Suppress ACPI BIOS errors (harmless BIOS bugs, but noisy)
    "acpi.debug_level=0"

  ];
}

