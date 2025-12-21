# Development configuration - Docker, languages, tools
{ pkgs, ... }: {
  # Docker
  virtualisation.docker = {
    enable = true;
    # Rootless mode (more secure, but some compatibility issues)
    # rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
  };

  # NVIDIA Container Toolkit (for --gpus all support)
  hardware.nvidia-container-toolkit.enable = true;

  # GPG agent for signing commits
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Git (basic system-wide, detailed config in home-manager)
  programs.git.enable = true;

  # Development packages
   environment.systemPackages = with pkgs; [
     # Editors
      code-cursor-fhs  # Cursor IDE (needs overlay or FHS)
  
     # Nix tools
      nix-index    # nix-locate command
      comma        # Run programs without installing: , program

     # Common CLI
     curl
     wget
     nano
     tree
     unzip
     ripgrep
     zip
     pciutils
     usbutils
     jq  
     openssh
     file
     which
     lsof
     killall
     nano
     btop
     man-pages
     firefox

     # Languages (prefer per-project with devShells/direnv)
      go
#      rustup
      python3
      dotnet-sdk_10
   ];

  # nix-index for command-not-found (enabled)
   programs.nix-index = {
     enable = true;
     enableZshIntegration = true;
   };
}

