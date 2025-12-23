# XDG portals, MIME handlers, secrets
# Shared module for desktop functionality
{ pkgs, ... }: {
  # XDG portal (screen sharing, file dialogs, etc.)
  xdg.portal = {
    enable = true;
    # Use KDE portal for Plasma
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
  };

  # GVFS for file manager features (MTP, SMB, trash)
  services.gvfs.enable = true;

  # Polkit (privilege escalation dialogs)
  security.polkit.enable = true;

  # D-Bus
  services.dbus.enable = true;

  # Ensure xdg-open is available
  environment.systemPackages = with pkgs; [
    xdg-utils
  ];
}


