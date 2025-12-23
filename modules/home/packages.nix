# Common user packages
# Shared packages module for all users
{ pkgs, inputs, ... }: let
  system = pkgs.system;
in {
  home.packages = with pkgs; [
    # Theming (required for plasma.nix)
    bibata-cursors
    papirus-icon-theme

    # Fonts
    inter
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono

    # KDE extras
    kdePackages.kde-gtk-config
    kdePackages.breeze-gtk

    # Browsers
    google-chrome

    # Communication
    vesktop  # Discord with Vencord mod
    teams-for-linux

    # Media
    ytmdesktop
    vlc

    # Office suite
    libreoffice-qt6
    hunspell
    hunspellDicts.en_US
    hunspellDicts.nl_NL

    # Development tools
    nodejs_24

    # Factory AI droid CLI (via nix-ai-tools flake)
    inputs.nix-ai-tools.packages.${system}.droid

    # GitHub Copilot CLI
    github-copilot-cli

    # Utilities
    rofi
  ];
}


