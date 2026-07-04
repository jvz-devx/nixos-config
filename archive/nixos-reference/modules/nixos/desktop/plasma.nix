# KDE Plasma 6 configuration
# Shared module for all hosts using Plasma desktop
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.desktop.plasma.enable = lib.mkEnableOption "KDE Plasma 6 desktop environment";

  config = lib.mkIf config.myConfig.desktop.plasma.enable {
    # Enable X11 (needed for some apps, SDDM, fallback)
    services.xserver = {
      enable = true;
      # Exclude default X11 packages we don't want
      excludePackages = [pkgs.xterm];
    };

    # Display manager
    services.displayManager.sddm = {
      enable = true;
      # Keep the greeter on X11. The SDDM Wayland greeter path is still
      # experimental and currently crashes on this host's NVIDIA stack
      # before the login screen becomes usable.
      wayland.enable = false;
    };

    # KDE Plasma 6
    services.desktopManager.plasma6.enable = true;
    programs.kdeconnect.enable = true;

    # Leave the default session unset so SDDM can offer the normal session
    # chooser; the important part is that the greeter itself stays off the
    # broken Wayland path.

    # SSH agent integration with KWallet
    programs.ssh.startAgent = true;
    programs.ssh.askPassword = lib.getExe pkgs.kdePackages.ksshaskpass;

    # KDE packages
    environment.systemPackages = with pkgs.kdePackages; [
      ksshaskpass
      kcalc
    ];

    # Enable nix-ld for running unpatched binaries
    programs.nix-ld.enable = true;
  };
}
