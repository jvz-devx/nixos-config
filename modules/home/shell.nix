# Shell configuration - Zsh, Oh-My-Zsh
# Shared shell module for all users
{
  pkgs,
  config,
  lib,
  ...
}: {
  # Add ~/.local/bin for AppImages and ~/.npm-global/bin for npm globals
  home.sessionPath = ["$HOME/.local/bin" "$HOME/.npm-global/bin"];

  # Default editor
  home.sessionVariables = {
    EDITOR = "nano";
    VISUAL = "nano";
    QT_STYLE_OVERRIDE = "kvantum";
    SKIP_HOST_UPDATE = "1";
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
      bwu = "bw-unlock"; # Quick unlock alias

      # System
      treesize = "sudo ncdu -x --exclude /mnt --exclude /media --exclude /tmp /";

      # Claude Code
      claude = "command claude --dangerously-skip-permissions";
      claude-team = "claude-team-fn";
      tmux-list = "tmux list-sessions";
      tmux-resume = "tmux attach-session -t";
      tmux-kill = "tmux kill-session -t";
      tmux-kill-all = "tmux kill-server";
    };

    # Shell functions and initialization
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # PokeFetch: Display random Pokemon + fastfetch on shell startup
        # Uses pokemon-colorscripts as fastfetch logo
        # Only run in interactive shells and not in subshells/scripts
        if [[ $- == *i* ]] && [[ -z "$POKEFETCH_SHOWN" ]]; then
          export POKEFETCH_SHOWN=1
          mkdir -p ~/.cache
          pokemon-colorscripts --no-title -r > ~/.cache/pokemon.txt 2>/dev/null
          if [[ -s ~/.cache/pokemon.txt ]]; then
            python3 /etc/nixos/assets/wallpaper/shell/pokefetch.py
            fastfetch --config pokefetch.json --logo ~/.cache/pokemon.txt --logo-type file-raw --logo-padding-top 1
          else
            fastfetch
          fi
        fi
      '')
      ''
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

        # Claude Code team mode (supports multiple sessions)
        claude-team-fn() {
          local name="''${1:-claude-$(date +%s)}"
          local cmd="command claude --dangerously-skip-permissions --teammate-mode tmux"
          if [[ -n "$TMUX" ]]; then
            tmux new-session -d -s "$name" "$cmd"
            tmux switch-client -t "$name"
          else
            tmux new-session -s "$name" "$cmd"
          fi
        }

        # Claude Code with Z.ai API
        claude-zai() {
          if [[ -f /run/secrets/zai_api_key ]]; then
            ANTHROPIC_AUTH_TOKEN=$(cat /run/secrets/zai_api_key) \
            ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic" \
            API_TIMEOUT_MS="3000000" \
            command claude --dangerously-skip-permissions "$@"
          else
            echo "Z.ai API key not found. Run 'sudo nixos-rebuild switch' first."
            return 1
          fi
        }
      ''
    ];
  };

  # Claude Code global settings (declarative, survives rebuilds)
  home.file.".claude/settings.json".text = builtins.toJSON {
    model = "opus";
    enabledPlugins = {
      "frontend-design@claude-plugins-official" = true;
      "rust-analyzer-lsp@claude-plugins-official" = true;
      "context7@claude-plugins-official" = true;
    };
    env = {
      CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1";
    };
    attribution = {
      commit = "";
    };
    statusLine = {
      type = "command";
      command = "bash ~/.claude/statusline-command.sh";
    };
  };

  # Claude Code status line script
  home.file.".claude/statusline-command.sh" = {
    text = ''
      #!/usr/bin/env bash

      # Read JSON input from stdin
      input=$(cat)

      # Extract values
      model_name=$(echo "$input" | jq -r '.model.display_name // .model.id')
      used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
      total_cost=$(echo "$input" | jq -r '.cost.total_cost_usd // 0')

      # Format cost
      cost_str=""
      if [ "$(echo "$total_cost > 0" | ${pkgs.bc}/bin/bc -l 2>/dev/null)" = "1" ]; then
        formatted=$(printf "%.2f" "$total_cost")
        cost_str=" | \$$formatted"
      else
        cost_str=" | \$0.00"
      fi

      # Build output
      output="$model_name"

      # Add context bar if available
      if [ -n "$used_pct" ]; then
        # Round to integer
        used_int=$(printf "%.0f" "$used_pct")
        remaining_int=$((100 - used_int))

        # Create progress bar (20 chars total)
        bar_length=20
        filled=$((used_int * bar_length / 100))
        empty=$((bar_length - filled))

        # Build bar with filled/empty segments
        bar="["
        for ((i=0; i<filled; i++)); do bar+="█"; done
        for ((i=0; i<empty; i++)); do bar+="░"; done
        bar+="]"

        output+=" $bar $used_int%"
      fi

      # Add cost
      output+="$cost_str"

      echo "$output"
    '';
    executable = true;
  };

  # Claude Code global skills (declarative, survives rebuilds)
  home.file.".claude/skills/rust-coder/SKILL.md".source = ./claude-skills/rust-coder.md;
  home.file.".claude/skills/rust-borrow-fixer/SKILL.md".source = ./claude-skills/rust-borrow-fixer.md;
  home.file.".claude/skills/rust-reviewer/SKILL.md".source = ./claude-skills/rust-reviewer.md;
  home.file.".claude/skills/rust-tester/SKILL.md".source = ./claude-skills/rust-tester.md;
  home.file.".claude/skills/rust-project-init/SKILL.md".source = ./claude-skills/rust-project-init.md;

  # Direnv integration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
