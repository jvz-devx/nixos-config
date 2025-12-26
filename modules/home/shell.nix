# Shell configuration - Zsh, Oh-My-Zsh
# Shared shell module for all users
{ pkgs, ... }: {
  # Default editor
  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
    QT_STYLE_OVERRIDE = "kvantum";
  };

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

      # Bitwarden
      bwu = "bw-unlock";  # Quick unlock alias
    };

    # Shell functions and initialization
    initContent = ''
      # Force nano as editor
      export EDITOR="nano"
      export VISUAL="nano"

      # Bitwarden CLI helpers
      # Login to Bitwarden using API key from sops secrets
      bw-login() {
        if [[ -f /run/secrets/bitwarden_client_id ]] && [[ -f /run/secrets/bitwarden_client_secret ]]; then
          export BW_CLIENTID=$(cat /run/secrets/bitwarden_client_id)
          export BW_CLIENTSECRET=$(cat /run/secrets/bitwarden_client_secret)
          bw login --apikey
          unset BW_CLIENTID BW_CLIENTSECRET
        else
          echo "Bitwarden secrets not found. Run 'sudo nixos-rebuild switch' first."
          return 1
        fi
      }

      # Unlock Bitwarden and export session
      bw-unlock() {
        # Check if already logged in
        if ! bw status 2>/dev/null | grep -q '"status":"unlocked"'; then
          if bw status 2>/dev/null | grep -q '"status":"unauthenticated"'; then
            echo "Not logged in. Running bw-login first..."
            bw-login || return 1
          fi
          echo "Unlocking vault (enter master password)..."
          export BW_SESSION=$(bw unlock --raw)
          if [[ -n "$BW_SESSION" ]]; then
            echo "Vault unlocked! BW_SESSION exported."
          else
            echo "Failed to unlock vault."
            return 1
          fi
        else
          echo "Vault already unlocked."
        fi
      }

      # Get a password by name
      bwget() {
        if [[ -z "$1" ]]; then
          echo "Usage: bwget <search-term>"
          return 1
        fi
        bw get password "$1"
      }
    '';
  };

  # Direnv integration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}


