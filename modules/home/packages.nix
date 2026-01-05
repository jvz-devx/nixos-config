# Common user packages
# Shared packages module for all users
{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Browsers
    # google-chrome.override (moved to packages/chrome.nix)

    # Media
    vlc
    # stremio-wrapped (moved to packages/stremio.nix)

    # Office suite
    libreoffice-qt6
    hunspell
    hunspellDicts.en_US
    hunspellDicts.nl_NL

    # Documentation
    pandoc         # Document converter (includes CLI)

    # System
    gparted        # Partition editor

    # Utilities
    rofi
    nano

    # Password management
    bitwarden-cli
    bitwarden-desktop
  ];
}
