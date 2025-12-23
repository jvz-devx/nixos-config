# Tailscale VPN configuration
# Shared Tailscale module for all hosts
{ ... }: {
  # Enable Tailscale service
  services.tailscale.enable = true;

  # Open firewall for Tailscale
  networking.firewall = {
    # Trust the Tailscale interface
    trustedInterfaces = [ "tailscale0" ];
    # Allow Tailscale traffic
    checkReversePath = "loose";
  };
}


