# Tailscale VPN configuration
# Shared Tailscale module for all hosts
{ config, lib, pkgs, ... }: {
  options.myConfig.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN service";
    
    operator = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "User to set as Tailscale operator (allows GUI apps like ktailctl to work without sudo)";
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
    systemd.services.tailscaled-autoconnect = {
      description = "Automatic Tailscale authentication";
      after = [ "network-online.target" "tailscaled.service" "sops-install-secrets.service" ];
      wants = [ "network-online.target" "tailscaled.service" "sops-install-secrets.service" ];
      wantedBy = [ "multi-user.target" ];
      
      # Override the built-in script to be more robust and use --reset
      script = lib.mkForce ''
        getState() {
          ${pkgs.tailscale}/bin/tailscale status --json --peers=false 2>/dev/null | ${pkgs.jq}/bin/jq -r '.BackendState' || echo "Unknown"
        }

        echo "Starting Tailscale autoconnect loop..."
        lastState=""
        while true; do
          state="$(getState)"
          if [[ "$state" != "$lastState" ]]; then
            echo "Current Tailscale state: $state"
            case "$state" in
              NeedsLogin|NeedsMachineAuth|Stopped)
                echo "Server needs authentication, sending auth key"
                if [[ -f ${config.sops.secrets.tailscale_auth_key.path} ]]; then
                  ${pkgs.tailscale}/bin/tailscale up --reset \
                    --exit-node-allow-lan-access \
                    --advertise-exit-node \
                    --auth-key "$(cat ${config.sops.secrets.tailscale_auth_key.path})" || echo "tailscale up failed, retrying..."
                else
                  echo "Waiting for Tailscale auth key secret to be decrypted..."
                fi
                ;;
              Running)
                echo "Tailscale is running, ensuring flags are set"
                ${pkgs.tailscale}/bin/tailscale up \
                  --exit-node-allow-lan-access \
                  --advertise-exit-node || echo "tailscale up (refresh) failed"
                exit 0
                ;;
              *)
                echo "Waiting for transition (current: $state)"
                ;;
            esac
          fi
          lastState="$state"
          sleep 5
        done
      '';

      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
        # Retry on failure
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
      # Trust the Tailscale interface
      trustedInterfaces = [ "tailscale0" ];
      # Allow Tailscale traffic
      checkReversePath = "loose";
    };
  };
}
