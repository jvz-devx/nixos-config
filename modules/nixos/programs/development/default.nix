# Development configuration - Shared options and services
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.programs.development.enable = lib.mkEnableOption "Development tools (Docker, languages, CLI tools)";

  imports = [
    ./cli.nix
    ./gui.nix
  ];

  config = lib.mkIf config.myConfig.programs.development.enable {
    # Docker
    virtualisation.docker.enable = true;

    # NVIDIA Container Toolkit (for --gpus all support)
    # Only enable if NVIDIA hardware is configured AND not in integrated mode
    hardware.nvidia-container-toolkit.enable = let
      cfg = config.myConfig.hardware.nvidia;
      isLaptop = cfg.isLaptop or false;
      gpuMode =
        cfg.mode or (
          if isLaptop
          then "dedicated"
          else "desktop"
        );
    in
      (cfg.enable or false) && gpuMode != "integrated";

    # GPG agent for signing commits
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = false; # Using standard SSH agent with ksshaskpass instead
      pinentryPackage = pkgs.pinentry-qt; # Use KDE's pinentry for Plasma integration
    };

    # Direnv for automatic environment loading
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Git (basic system-wide, detailed config in home-manager)
    programs.git.enable = true;

    # nix-index for command-not-found
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}
