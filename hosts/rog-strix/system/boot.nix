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
  # TODO: Choose your kernel:
   boot.kernelPackages = pkgs.linuxPackages_latest;  # Latest stable
  # boot.kernelPackages = pkgs.linuxPackages_6_12;    # Specific version
  # boot.kernelPackages = pkgs.linuxPackages_cachyos; # CachyOS (needs chaotic input)

  # Kernel parameters
  boot.kernelParams = [
    # NVIDIA Wayland support
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"

    # TODO: Add LUKS resume device for hibernation
    # "resume=/dev/disk/by-uuid/YOUR-SWAP-UUID"

    # TODO: Uncomment if brightness control doesn't work
    # "acpi_backlight=native"
  ];

  # TODO: LUKS encryption setup
  # boot.initrd.luks.devices."cryptroot" = {
  #   device = "/dev/disk/by-uuid/YOUR-LUKS-UUID";
  #   preLVM = true;
  #   allowDiscards = true;
  # };
}

