# Maintenance configuration - GC, store optimization, fwupd
# Shared maintenance module for all hosts
{ ... }: {
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
}


