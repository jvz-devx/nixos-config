# Development configuration - Docker, languages, tools
{ pkgs, ... }: {
  # Docker
  virtualisation.docker = {
    enable = true;
    # TODO: Rootless mode (more secure, but some compatibility issues)
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

  # TODO: Development packages
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

     # Languages (prefer per-project with devShells/direnv)
      nodejs_22
      go
#      rustup
      python3
      dotnet-sdk_10
   ];

  # TODO: nix-index for command-not-found
   programs.nix-index = {
     enable = true;
     enableZshIntegration = true;
   };
}

