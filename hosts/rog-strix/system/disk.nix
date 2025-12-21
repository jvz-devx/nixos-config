# Disk configuration - Btrfs, LUKS, swap, resume
{ ... }: {
  # Btrfs options
  # Note: Actual mount points are in hardware-configuration.nix
  # This file contains additional Btrfs-related settings

  # Enable periodic TRIM for SSDs
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };

  # Swap configuration
  # Note: Swap is already configured in hardware-configuration.nix
  # Swap device: /dev/disk/by-uuid/4d48cb91-7bfa-448e-bc21-93e228ddd729 (34.1G)
  # Hibernation resume device is configured in boot.nix

  # Btrfs scrub (monthly integrity check)
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = ["/"];
  };
}

