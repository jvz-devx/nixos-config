# Common user packages
# Shared packages module for all users
{ pkgs, inputs, ... }: {
  # Autostart applications
  xdg.configFile."autostart/ktailctl.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Tailscale
    Exec=ktailctl --minimized
    Icon=ktailctl
    Comment=Tailscale VPN Manager
    Categories=Network;
    X-GNOME-Autostart-enabled=true
  '';

  home.packages = with pkgs; [
    # Theming (required for plasma.nix)
    bibata-cursors
    tela-icon-theme
    nordzy-icon-theme
    nordic

    # Fonts
    inter
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono

    # KDE extras
    kdePackages.kde-gtk-config
    kdePackages.breeze-gtk
    kdePackages.qtstyleplugin-kvantum
    plasma-panel-colorizer

    # Browsers
    google-chrome

    # Communication
    vesktop  # Discord with Vencord mod
    teams-for-linux

    # Media
    ytmdesktop
    vlc

    # Games
    prismlauncher
    heroic         # GOG/Epic Games launcher
    ludusavi       # Game save backup tool
    proton-ge-custom # Custom Proton builds
    rpcs3          # PlayStation 3 emulator
    cemu           # Wii U emulator

    # Office suite
    libreoffice-qt6
    hunspell
    hunspellDicts.en_US
    hunspellDicts.nl_NL

    # Media/Content Creation
    obs-studio     # Screen recorder/streaming
    mpv            # Media player
    handbrake      # Video transcoder
    audacity       # Audio editing
    gimp           # Image editing
    inkscape       # Vector graphics

    # Documentation
    pandoc         # Document converter (includes CLI)

    # System
    gparted        # Partition editor

    # Development tools
    nodejs_24

    # Factory AI droid CLI (via nix-ai-tools flake)
    inputs.nix-ai-tools.packages.${pkgs.stdenv.hostPlatform.system}.droid

    # GitHub Copilot CLI
    github-copilot-cli

    # Utilities
    rofi
    nano

    # Password management
    bitwarden-cli
    bitwarden-desktop

    # Tailscale GUI (KDE system tray)
    ktailctl
  ];
}


