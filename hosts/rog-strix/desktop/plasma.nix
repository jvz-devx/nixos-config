# KDE Plasma 6 configuration
{ pkgs, ... }: {
  # Enable X11 (needed for some apps, SDDM, fallback)
  services.xserver.enable = true;

  # X11 configuration for NVIDIA
  services.xserver = {
    # Screen section for NVIDIA
    screenSection = ''
      Option "metamodes" "nvidia-auto-select +0+0 {ForceFullCompositionPipeline=On}"
      Option "AllowIndirectGLXProtocol" "off"
      Option "TripleBuffer" "on"
    '';
  };

  # Display manager
  services.displayManager.sddm = {
    enable = true;
    # Disable Wayland for SDDM when using dGPU mode
    # NVIDIA + MUX switch + Wayland can be problematic
    # Re-enable when in hybrid mode if desired
    wayland.enable = false;
  };

  # KDE Plasma 6
  services.desktopManager.plasma6.enable = true;

  # Default session - X11 for stability with dGPU mode
  # Change to "plasma" (Wayland) when in hybrid mode if desired
  services.displayManager.defaultSession = "plasmax11";

  # Exclude some default KDE apps if desired
  # environment.plasma6.excludePackages = with pkgs.kdePackages; [
  #   elisa       # Music player
  #   konsole     # Terminal (if using different terminal)
  # ];

  # TODO: Additional Plasma packages
  # environment.systemPackages = with pkgs; [
  #   kdePackages.kde-gtk-config    # GTK theme integration
  #   kdePackages.breeze-gtk        # Breeze theme for GTK
  # ];
}

