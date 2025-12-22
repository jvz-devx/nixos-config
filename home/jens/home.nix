# Home Manager configuration for jens
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  # Access flake inputs for packages
  system = "x86_64-linux";
in {
  imports = [
    ./shell.nix
    ./programs.nix
    ./plasma.nix
  ];

  # Home Manager settings
  home = {
    username = "jens";
    homeDirectory = "/home/jens";

    # Packages to install for this user
    packages = with pkgs; [
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
      
      # Kvantum for application transparency and blur (Qt6 for Plasma 6)
      # Note: Kvantum for Qt6 is experimental - blur may not work fully
      kdePackages.qtstyleplugin-kvantum

      # Browsers
      google-chrome

      # Communication
      vesktop  # Discord with Vencord mod
      teams-for-linux

      # Media
      ytmdesktop  # YouTube Music Desktop
      # spotify
      vlc

      # Development tools
      # Node.js 24 (includes npm, so no need for separate nodePackages.npm)
      nodejs_24
      # Note: npm is included with nodejs_24, so nodePackages.npm is not needed
      
      # Factory AI droid CLI (via nix-ai-tools flake)
      inputs.nix-ai-tools.packages.${system}.droid
      
      # GitHub Copilot CLI (available in nixpkgs)
      github-copilot-cli
      
      # CodeRabbit CLI (custom package) - DISABLED
      # The CodeRabbit binary is a Bun-based application that checks its execution context
      # to determine whether to run as CodeRabbit CLI or as generic Bun runtime.
      # 
      # Issues encountered:
      # 1. Manual patchelf: Causes "unsupported version 0 of Verdef record" errors and segfaults
      #    - The binary has complex ELF structures that manual patchelf can't handle properly
      # 2. autoPatchelfHook: Successfully patches the binary without crashes, but:
      #    - The binary always shows Bun help instead of CodeRabbit help
      #    - Tried exec -a "coderabbit" wrapper to set argv[0] - didn't work
      #    - Tried symlinks - didn't work
      #    - The binary appears to check something else (possibly /proc/self/exe, embedded
      #      resources, or environment variables) rather than just argv[0]
      # 3. The fresh binary works correctly when downloaded directly, but after Nix patching
      #    it loses the ability to detect it should run as CodeRabbit
      #
      # Possible solutions not yet tried:
      # - Use buildFHSUserEnv to run in a more traditional Linux environment
      # - Check if there are environment variables the binary expects
      # - Investigate if the binary has embedded resources that get corrupted during patching
      # - Use a different packaging approach (e.g., AppImage-style wrapper)
      #
      # For now, users can install CodeRabbit manually:
      #   curl -fsSL https://cli.coderabbit.ai/install.sh | bash
      # inputs.self.packages.${system}.coderabbit
      
      # Codex CLI (via flake)
      # Access via: nix run github:sadjow/codex-nix#codex
      
      # Utilities
      rofi  # Application launcher (alternative to KRunner)
      # Note: nvidia-settings is available system-wide via hardware.nvidia.nvidiaSettings = true
      # bitwarden
      # flameshot
    ];
  };

  # Enable home-manager itself
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "26.05";
}

