# Tailscale VPN configuration
{ pkgs, ... }: {
  # Enable Tailscale service
  services.tailscale.enable = true;

  # Open firewall for Tailscale
  # Tailscale uses port 41641/UDP for coordination
  networking.firewall = {
    # Trust the Tailscale interface
    trustedInterfaces = [ "tailscale0" ];
    # Allow Tailscale traffic
    checkReversePath = "loose";
  };

  # Optional: Enable Tailscale as an exit node (allows other devices to route through this machine)
  # Uncomment the following if you want this machine to act as an exit node:
  # services.tailscale.useRoutingFeatures = "server";

  # Optional: Set up Tailscale to start on boot (requires authentication first)
  # After first login with `sudo tailscale up`, the service will persist
}










