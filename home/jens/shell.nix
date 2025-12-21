# Shell configuration - Zsh, Oh-My-Zsh, Starship
{ pkgs, ... }: {
  # Zsh
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    # Enable history substring search (works with history-substring-search plugin)
    enableCompletion = true;

    # Oh-My-Zsh
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";  # TODO: Choose your theme
      plugins = [
        # Version control
        "git"
        "gitfast"  # Faster git completion
        
        # Development tools
        "docker"
        "docker-compose"
        "kubectl"
        "direnv"
        
        # System utilities
        "extract"  # Extract any archive: extract file.tar.gz
        "sudo"  # Double ESC to add sudo prefix
        "command-not-found"  # Suggest packages for missing commands
        
        # Navigation & history
        "z"  # Jump to frequently used directories
        "history-substring-search"  # Search history with up/down arrows
        
        # Productivity
        "colored-man-pages"  # Colored man pages
        "copyfile"  # Copy file content to clipboard: copyfile file.txt
        "copypath"  # Copy file path to clipboard: copypath
        "web-search"  # Search web: google "query" or ddg "query"
        
        # NixOS specific
        "nix-shell"  # Nix shell integration
      ];
    };

    # Shell aliases
    shellAliases = {
      # Nix
      rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#rog-strix";
      update = "nix flake update /etc/nixos";

      # General
      ll = "ls -la";
      ".." = "cd ..";
      "..." = "cd ../..";

      # Git shortcuts
      gs = "git status";
      gd = "git diff";
      gc = "git commit";
      gp = "git push";
      gl = "git pull";

      # TODO: Add your aliases
      docker-compose = "docker compose";
      crr = "coderabbit review --plain --uncommitted";
    };

    # Extra configuration
    initContent = ''
      # TODO: Add custom shell initialization here
    '';
  };

  # TODO: Alternative to Oh-My-Zsh - Starship prompt
  # programs.starship = {
  #   enable = true;
  #   settings = {
  #     # See https://starship.rs/config/
  #   };
  # };

  # Direnv integration (loads .envrc files automatically)
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}

