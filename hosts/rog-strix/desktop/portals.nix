# XDG portals, MIME handlers, secrets
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

  # Secrets (KWallet is included with Plasma, but ensure it's working)
  # KWallet is automatically enabled with Plasma 6

  # TODO: Set default applications via home-manager or manually
  # These are typically set per-user in ~/.config/mimeapps.list
  # or via System Settings > Default Applications

  # Ensure xdg-open is available
  environment.systemPackages = with pkgs; [
    xdg-utils
  ];
}

