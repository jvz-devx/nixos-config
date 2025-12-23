# KDE Plasma 6 configuration
# Shared module for all hosts using Plasma desktop
{ pkgs, ... }: {
  # Enable X11 (needed for some apps, SDDM, fallback)
  services.xserver = {
    enable = true;
    # Exclude default X11 packages we don't want
    excludePackages = [ pkgs.xterm ];
  };

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # KDE Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Default session - Wayland
  services.displayManager.defaultSession = "plasma";
}


