# Shell configuration - Zsh, Oh-My-Zsh
# Shared shell module for all users
{
  pkgs,
  config,
  lib,
  ...
}: let
  cliproxyapiRemoteBaseUrl = "http://chat-api.jensvanzutphen.com:8317";
  cliproxyapiRemoteModel = "gpt-5.5";
  cliproxyapiRemoteSmallModel = "gpt-5.4-mini";
  cliproxyapiRemoteSecretPath = "/run/secrets/cliproxyapi_remote_api_key";
in {
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
      claude = "claude-proxy";
      claude-team = "claude-team-fn";

      # Pi agent teams
      pi-team-tmux = "pi-team-tmux-fn";

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
          if command -v pokemon-colorscripts >/dev/null 2>&1; then
            pokemon-colorscripts --no-title -r > ~/.cache/pokemon.txt 2>/dev/null
          fi
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
          local cmd='zsh -lic "claude-proxy --teammate-mode tmux"'
          if [[ -n "$TMUX" ]]; then
            tmux new-session -d -s "$name" "$cmd"
            tmux switch-client -t "$name"
          else
            tmux new-session -s "$name" "$cmd"
          fi
        }

        # Pi agent teams in tmux: dynamic teammate panes.
        # Usage:
        #   pi-team-tmux           # unique pi-teams-* session, leader only
        #   pi-team-tmux myteam    # unique myteam-* session, leader only
        # Then spawn teammates inside Pi; each spawn creates an interactive pane.
        pi-team-tmux-fn() {
          local prefix="''${1:-pi-teams}"
          local unique="$(date +%Y%m%d-%H%M%S)-$$"
          local session="$prefix-$unique"
          local run_dir="$PWD"
          local teams_root="''${PI_TEAMS_ROOT_DIR:-/tmp/$session}"
          local fork_ext="$run_dir/../pi-agent-teams/extensions/teams/index.ts"
          local source_ext="/home/jens/Documents/source/pi-agent-teams/extensions/teams/index.ts"
          local installed_ext="/home/jens/.npm-global/lib/node_modules/@tmustier/pi-agent-teams/extensions/teams/index.ts"
          local ext=""

          if [[ -f "$fork_ext" ]]; then
            ext="$(realpath "$fork_ext")"
          elif [[ -f "$source_ext" ]]; then
            ext="$source_ext"
          elif [[ -f "$installed_ext" ]]; then
            ext="$installed_ext"
          else
            echo "Pi agent teams extension entry not found." >&2
            return 1
          fi

          while tmux has-session -t "$session" 2>/dev/null; do
            unique="$(date +%Y%m%d-%H%M%S)-$$-$RANDOM"
            session="$prefix-$unique"
            teams_root="''${PI_TEAMS_ROOT_DIR:-/tmp/$session}"
          done

          mkdir -p "$teams_root"
          echo "Starting Pi Teams leader in $run_dir..."
          echo "extension: $ext"
          tmux new-session -d -s "$session" -n team -c "$run_dir" \
            "env PI_TEAMS_ROOT_DIR=''${(q)teams_root} PI_TEAMS_SPAWN_MODE=tmux PI_TEAMS_TMUX_LEADER_WIDTH_PCT=40 pi --no-extensions -e ''${(q)ext}"

          echo ""
          echo "OK"
          echo "tmux session: $session"
          echo "teams root:   $teams_root"
          echo ""
          echo "Spawn teammates inside Pi with /team spawn or delegation; panes split dynamically."
          echo ""

          if [[ -n "$TMUX" ]]; then
            tmux switch-client -t "$session"
          else
            tmux attach -t "$session"
          fi
        }

        # Claude Code via homelab CLIProxyAPI
        claude-proxy() {
          if [[ -f ${cliproxyapiRemoteSecretPath} ]]; then
            env \
              -u ANTHROPIC_API_KEY \
              -u CLAUDE_CODE_API_BASE_URL \
              ANTHROPIC_AUTH_TOKEN="$(cat ${cliproxyapiRemoteSecretPath})" \
              ANTHROPIC_BASE_URL="${cliproxyapiRemoteBaseUrl}" \
              ANTHROPIC_MODEL="${cliproxyapiRemoteModel}" \
              ANTHROPIC_DEFAULT_HAIKU_MODEL="${cliproxyapiRemoteSmallModel}" \
              ANTHROPIC_SMALL_FAST_MODEL="${cliproxyapiRemoteSmallModel}" \
              CLAUDE_CODE_SUBAGENT_MODEL="${cliproxyapiRemoteSmallModel}" \
              API_TIMEOUT_MS="3000000" \
              claude --dangerously-skip-permissions "$@"
          else
            echo "CLIProxyAPI remote API key not found. Run 'sudo nixos-rebuild switch' first."
            return 1
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

  # Claude Code global settings (repo-backed and writable by Claude Code)
  home.file.".claude/settings.json" = {
    source = config.lib.file.mkOutOfStoreSymlink "/etc/nixos/modules/home/base/claude-settings.json";
    force = true;
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
  home.file.".claude/skills/rust-coder/SKILL.md".source = ../claude-skills/rust-coder.md;
  home.file.".claude/skills/rust-borrow-fixer/SKILL.md".source = ../claude-skills/rust-borrow-fixer.md;
  home.file.".claude/skills/rust-reviewer/SKILL.md".source = ../claude-skills/rust-reviewer.md;
  home.file.".claude/skills/rust-tester/SKILL.md".source = ../claude-skills/rust-tester.md;
  home.file.".claude/skills/rust-project-init/SKILL.md".source = ../claude-skills/rust-project-init.md;
  home.file.".claude/skills/nix-writer/SKILL.md".source = ../claude-skills/nix-writer.md;
  home.file.".claude/skills/cloudflare-cf/SKILL.md".source = ../claude-skills/cloudflare-cf.md;
  home.file.".claude/skills/context-handoff/SKILL.md".source = ../claude-skills/context-handoff.md;
  home.file.".claude/skills/delegate-plan/SKILL.md".source = ../claude-skills/delegate-plan.md;
  home.file.".claude/skills/skill-creator".source = ../claude-skills/skill-creator;

  # Codex global skills (declarative, survives rebuilds)
  home.file.".codex/skills/grill-me/SKILL.md".source = ../codex-skills/grill-me/SKILL.md;
  home.file.".codex/skills/hyprland-gaming/SKILL.md".source = ../codex-skills/hyprland-gaming/SKILL.md;

  # Direnv integration
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
