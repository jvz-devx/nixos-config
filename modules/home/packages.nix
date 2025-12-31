# Common user packages
# Shared packages module for all users
{ pkgs, inputs, lib, ... }: let
  stremio-pkgs = import inputs.nixpkgs-stremio {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # Wrap Stremio to unset QT_PLUGIN_PATH to avoid library mismatch with Plasma 6 environment
  # and ensure it can find mpv and ffmpeg for playback (using pinned versions for compatibility)
  stremio-wrapped = pkgs.runCommand "stremio" {
    nativeBuildInputs = [ pkgs.makeWrapper ];
  } ''
    mkdir -p $out/share
    ln -s ${stremio-pkgs.stremio}/share/* $out/share/
    makeWrapper ${stremio-pkgs.stremio}/bin/stremio $out/bin/stremio \
      --unset QT_PLUGIN_PATH \
      --unset QT_QPA_PLATFORMTHEME \
      --unset QT_STYLE_OVERRIDE \
      --prefix PATH : ${lib.makeBinPath [ stremio-pkgs.mpv stremio-pkgs.ffmpeg pkgs.vlc pkgs.yt-dlp ]} \
      --set LD_LIBRARY_PATH ${lib.makeLibraryPath [ pkgs.libva ]}
  '';
in {
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
    kdePackages.breeze
    kdePackages.qtstyleplugin-kvantum
    plasma-panel-colorizer

    # Browsers
    (google-chrome.override {
      commandLineArgs = [
        "--ozone-platform-hint=auto"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization"
        "--disable-features=UseChromeOSDirectVideoDecoder"
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
      ];
    })

    # Communication
    vesktop  # Discord with Vencord mod
    teams-for-linux

    # Media
    ytmdesktop
    vlc
    stremio-wrapped

    # Games
    prismlauncher
    heroic         # GOG/Epic Games launcher
    ludusavi       # Game save backup tool
    inputs.chaotic.packages.${pkgs.stdenv.hostPlatform.system}.proton-ge-custom # Custom Proton builds
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


