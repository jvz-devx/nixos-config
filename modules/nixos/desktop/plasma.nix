# KDE Plasma 6 configuration
# Shared module for all hosts using Plasma desktop
{ config, lib, pkgs, ... }: {
  options.myConfig.desktop.plasma.enable = lib.mkEnableOption "KDE Plasma 6 desktop environment";

  config = lib.mkIf config.myConfig.desktop.plasma.enable {
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

    # SSH agent integration with KWallet
    programs.ssh.startAgent = true;
    programs.ssh.askPassword = "${pkgs.kdePackages.ksshaskpass}/bin/ksshaskpass";

    # Ensure ksshaskpass is available
    environment.systemPackages = [ pkgs.kdePackages.ksshaskpass ];

    # Enable nix-ld for running unpatched binaries
    programs.nix-ld.enable = true;
  };
}


