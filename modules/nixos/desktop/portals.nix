# XDG portals, MIME handlers, secrets
# Shared module for desktop functionality
{
  config,
  lib,
  options,
  pkgs,
  ...
}: {
  options.myConfig.desktop.portals.enable = lib.mkEnableOption "XDG portals and desktop integration (screen sharing, file dialogs, etc.)";

  config = lib.mkIf config.myConfig.desktop.portals.enable ({
      # XDG portal (screen sharing, file dialogs, etc.)
      xdg.portal = {
        enable = true;
        # Add GTK portal for compatibility with non-Qt apps (like some Flatpaks)
        # xdg-desktop-portal-kde is automatically added by the Plasma module
        extraPortals = [pkgs.xdg-desktop-portal-gtk];
        config.common.default = ["kde"];
        xdgOpenUsePortal = true;
      };

      # GVFS for file manager features (MTP, SMB, trash)
      services.gvfs.enable = true;

      # Secret service backend (for apps using libsecret like CodeRabbit)
      services.gnome.gnome-keyring.enable = true;

      # Polkit (privilege escalation dialogs)
      security.polkit.enable = true;

      # D-Bus
      services.dbus.enable = true;

      # Ensure standard desktop utilities and libraries are available
      environment.systemPackages = with pkgs; [
        xdg-utils
        libsecret # Library for secret storage communication
      ];
    }
    // lib.optionalAttrs (lib.hasAttrByPath ["services" "gnome" "gcr-ssh-agent" "enable"] options) {
      # Disable GNOME's GCR SSH agent as it conflicts with programs.ssh.startAgent
      # which is used for KWallet integration in plasma.nix
      services.gnome.gcr-ssh-agent.enable = false;
    });
}
