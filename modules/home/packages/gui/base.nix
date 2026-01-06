{pkgs, ...}: {
  home.packages = with pkgs; [
    # Office suite
    libreoffice-qt6

    # System
    gparted # Partition editor

    # Utilities
    rofi

    # Password management
    bitwarden-desktop
  ];
}
