# Maintenance configuration - GC, store optimization, fwupd
# Shared maintenance module for all hosts
{
  config,
  lib,
  ...
}: {
  options.myConfig.services.maintenance.enable = lib.mkEnableOption "System maintenance (GC, store optimization, firmware updates)";

  config = lib.mkIf config.myConfig.services.maintenance.enable {
    # Nix garbage collection
    nix.gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 14d";
    };

    # Nix store optimization (deduplication)
    nix.settings.auto-optimise-store = true;

    # Firmware updates (LVFS)
    services.fwupd.enable = true;
  };
}
