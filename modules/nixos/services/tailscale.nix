# Tailscale VPN configuration
# Shared Tailscale module for all hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN service";

    operator = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "User to set as Tailscale operator (allows GUI apps like ktailctl to work without sudo)";
    };

    advertiseExitNode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Advertise this machine as a Tailscale exit node";
    };
  };

  config = lib.mkIf config.myConfig.services.tailscale.enable {
    # Enable secrets management (provides the auth key)
    myConfig.secrets.enable = true;

    # Enable Tailscale service with automatic authentication
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      # Use the decrypted auth key from sops
      authKeyFile = config.sops.secrets.tailscale_auth_key.path;
      # Set operator if specified (allows ktailctl and other GUI tools to work)
      extraSetFlags = lib.optionals (config.myConfig.services.tailscale.operator != null) [
        "--operator=${config.myConfig.services.tailscale.operator}"
      ];
    };

    # Fix autoconnect service timing - wait for tailscaled to be truly ready
    # We use a oneshot service that runs once at boot/activation to ensure Tailscale is up.
    # This avoids a "while true" loop that would prevent users from manually stopping Tailscale.
    systemd.services.tailscaled-autoconnect = {
      description = "Automatic Tailscale authentication";
      after = ["network-online.target" "tailscaled.service" "sops-install-secrets.service"];
      wants = ["network-online.target" "tailscaled.service" "sops-install-secrets.service"];
      wantedBy = ["multi-user.target"];

      # Override the built-in script to be more robust
      # Note: --reset is only used for initial auth (NeedsLogin/Stopped) to ensure a clean state.
      # For the Running case, we use `tailscale up` without --reset to avoid disrupting active connections.
      script = lib.mkForce ''
        getState() {
          ${lib.getExe pkgs.tailscale} status --json --peers=false 2>/dev/null | ${lib.getExe' pkgs.jq "jq"} -r '.BackendState' || echo "Unknown"
        }

        echo "Checking Tailscale status..."
        state="$(getState)"
        echo "Current Tailscale state: $state"

        case "$state" in
          NeedsLogin|NeedsMachineAuth|Stopped)
            echo "Tailscale needs authentication or is stopped, sending auth key..."
            if [[ -f ${config.sops.secrets.tailscale_auth_key.path} ]]; then
              ${lib.getExe pkgs.tailscale} up --reset \
                ${lib.escapeShellArgs config.services.tailscale.extraSetFlags} \
                ${lib.optionalString config.myConfig.services.tailscale.advertiseExitNode "--advertise-exit-node"} \
                --accept-routes --accept-dns \
                --auth-key "$(cat ${config.sops.secrets.tailscale_auth_key.path})"
            else
              echo "Tailscale auth key secret not found at ${config.sops.secrets.tailscale_auth_key.path}"
              exit 1
            fi
            ;;
          Running)
            # Don't use --reset here to avoid disrupting active VPN connections.
            # `tailscale up` without --reset will update flags without disconnecting.
            echo "Tailscale is already running, ensuring flags are set..."
            ${lib.getExe pkgs.tailscale} up \
              ${lib.escapeShellArgs config.services.tailscale.extraSetFlags} \
              ${lib.optionalString config.myConfig.services.tailscale.advertiseExitNode "--advertise-exit-node"} \
              --accept-routes --accept-dns
            ;;
          *)
            echo "Tailscale is in state $state, no action needed."
            ;;
        esac
      '';

      serviceConfig = {
        Type = lib.mkForce "oneshot";
        RemainAfterExit = true;
        ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 2";
        # Retry on failure (e.g. network not ready or secrets not yet decrypted)
        Restart = "on-failure";
        RestartSec = "10s";
      };
      # Don't fail the entire activation if this fails immediately
      unitConfig = {
        StartLimitIntervalSec = 60;
        StartLimitBurst = 5;
      };
    };

    # Open firewall for Tailscale
    networking.firewall = {
      # Trust the Tailscale interface and Docker bridge interfaces
      trustedInterfaces = ["tailscale0" "docker0" "br-+"];
      # Allow Tailscale traffic
      checkReversePath = "loose";
    };

    # Fix Docker bridge traffic being hijacked by Tailscale's routing table (table 52).
    # These rules ensure Docker subnet traffic uses the main routing table instead.
    networking.localCommands = ''
      ${lib.getExe' pkgs.iproute2 "ip"} rule add to 172.16.0.0/12 lookup main priority 5200 2>/dev/null || true
      ${lib.getExe' pkgs.iproute2 "ip"} rule add from 172.16.0.0/12 lookup main priority 5200 2>/dev/null || true
    '';
  };
}
