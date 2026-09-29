let
  # One key for every homelab and Hetzner host, pinned so logins never
  # depend on what the SSH agent happens to hold.
  homelab = {
    IdentityFile = "~/.ssh/homelab";
    IdentitiesOnly = true;
  };
in {
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;

    # Local-only host files (e.g. work servers) that stay out of this repo.
    includes = ["config.d/*"];

    settings = {
      # Fedora workstation
      "fedora" =
        homelab
        // {
          HostName = "192.168.1.57";
          User = "jens";
        };

      "github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      "gitlab.com *.gitlab.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_ed25519_gitlab";
        IdentitiesOnly = true;
        AddKeysToAgent = "yes";
      };

      # Proxmox hosts
      "node1" =
        homelab
        // {
          HostName = "192.168.1.201";
          User = "root";
        };

      "node2" =
        homelab
        // {
          HostName = "192.168.1.202";
          User = "root";
        };

      # Proxmox guests on node1
      "homeassistant" =
        homelab
        // {
          HostName = "192.168.1.27";
          User = "root";
        };

      "hermes" =
        homelab
        // {
          HostName = "192.168.1.54";
          User = "ubuntu";
        };

      # Proxmox guests on node2
      "k3s-node" =
        homelab
        // {
          HostName = "192.168.1.100";
          User = "root";
        };

      # Hetzner k3s server, reached over Tailscale (public SSH is IP-restricted)
      "hetzner" =
        homelab
        // {
          HostName = "hetzner-k3s-1";
          User = "root";
        };

      "*" = {
        IdentityFile = "~/.ssh/id_ed25519";
        AddKeysToAgent = "yes";
      };
    };
  };
}
