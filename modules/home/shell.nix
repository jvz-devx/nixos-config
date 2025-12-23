# Shell configuration - Zsh, Oh-My-Zsh
# Shared shell module for all users
{ pkgs, ... }: {
  # Zsh
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    # Oh-My-Zsh
    oh-my-zsh = {
      enable = true;
      theme = "robbyrussell";
      plugins = [
        # Version control
        "git"
        "gitfast"

        # Development tools
        "docker"
        "docker-compose"
        "kubectl"
        "direnv"

        # System utilities
        "extract"
        "sudo"
        "command-not-found"

        # Navigation & history
        "z"
        "history-substring-search"

        # Productivity
        "colored-man-pages"
        "copyfile"
        "copypath"
        "web-search"

        # NixOS specific
        "nix-shell"
      ];
    };

    # Common shell aliases (can be extended per-user)
    shellAliases = {
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

      # Docker
      docker-compose = "docker compose";
    };
  };

  # Direnv integration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}


