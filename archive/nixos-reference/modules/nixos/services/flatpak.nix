# Flatpak support and integration
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.services.flatpak = {
    enable = lib.mkEnableOption "Flatpak support and Flathub repository";
    packages = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of Flatpak IDs to install from Flathub";
    };
    bundles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "List of Flatpak bundle URLs to install";
    };
  };

  config = lib.mkIf config.myConfig.services.flatpak.enable {
    # Enable Flatpak daemon
    services.flatpak.enable = true;

    # Fix for Flatpak apps not appearing in desktop menus and failing to open GUI
    # See: https://nixos.wiki/wiki/Flatpak
    services.dbus.packages = [pkgs.flatpak];
    system.fsPackages = [pkgs.flatpak];

    # Ensure Flatpak paths are in XDG_DATA_DIRS
    # This is often handled by services.flatpak.enable, but sometimes needs explicit help.
    # We use a more robust way to append these paths for all users.
    environment.extraInit = ''
      # Add Flatpak exports to XDG_DATA_DIRS if not already present
      if [[ -d "/var/lib/flatpak/exports/share" ]] && [[ ! "$XDG_DATA_DIRS" =~ "/var/lib/flatpak/exports/share" ]]; then
        export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:$XDG_DATA_DIRS"
      fi
      if [[ -d "$HOME/.local/share/flatpak/exports/share" ]] && [[ ! "$XDG_DATA_DIRS" =~ "$HOME/.local/share/flatpak/exports/share" ]]; then
        export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"
      fi
    '';

    # Global environment variables for Flatpak compatibility
    environment.sessionVariables = {
      # Fix for some webview-based Flatpaks on NVIDIA
      WEBKIT_DISABLE_COMPOSITING_MODE = "1";
      # Ensure Qt apps in Flatpak use the correct theme/portal
      QT_X11_NO_MITSHM = "1";
    };

    # Add Flathub repository and install packages automatically
    systemd.services.flatpak-repo = {
      description = "Add Flathub repository and install Flatpak packages";
      wantedBy = ["multi-user.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      path = [pkgs.flatpak];
      script = ''
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        ${lib.concatMapStringsSep "\n" (pkg: "flatpak install --noninteractive flathub ${pkg} || true") config.myConfig.services.flatpak.packages}
        ${lib.concatMapStringsSep "\n" (url: "flatpak install --noninteractive ${url} || true") config.myConfig.services.flatpak.bundles}
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # Ensure Discover and other tools are available
    # Discover is usually included with Plasma 6, but we ensure it's here
    # along with the flatpak icon themes if needed.
    environment.systemPackages = with pkgs; [
      kdePackages.discover
      gsettings-desktop-schemas
      dconf # GTK apps often need this for settings
      libportal-qt6 # Portal library for Qt6 apps (like DLSS-Updater)
    ];

    # Enable dconf service
    programs.dconf.enable = true;
  };
}
