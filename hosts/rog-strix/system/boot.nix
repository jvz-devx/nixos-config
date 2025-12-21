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

  # Hibernation resume device (swap partition)
  # Swap is configured in hardware-configuration.nix
  boot.resumeDevice = "/dev/disk/by-uuid/4d48cb91-7bfa-448e-bc21-93e228ddd729";

  # Kernel parameters
  boot.kernelParams = [
    # NVIDIA Wayland support
    "nvidia-drm.modeset=1"
    "nvidia-drm.fbdev=1"

    # Hibernation resume (required for hibernate to work)
    "resume=/dev/disk/by-uuid/4d48cb91-7bfa-448e-bc21-93e228ddd729"

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

