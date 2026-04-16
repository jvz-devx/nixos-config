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

    # Messaging
    telegram-desktop

    # AI Coding
    claude-code
    paseo
    # chell-desktop - AppImage installed at ~/.local/bin/chell-desktop
  ];
}
