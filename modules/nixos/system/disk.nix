# Disk configuration - TRIM, Btrfs scrub
# Shared disk module for all hosts
{
  config,
  lib,
  ...
}: {
  options.myConfig.system.disk.enable = lib.mkEnableOption "Disk maintenance (TRIM, Btrfs scrub)";

  config = lib.mkIf config.myConfig.system.disk.enable {
    # Enable periodic TRIM for SSDs
    services.fstrim = {
      enable = true;
      interval = "weekly";
    };

    # Btrfs scrub (monthly integrity check)
    # Only enable if using Btrfs
    services.btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = ["/"];
    };
  };
}
