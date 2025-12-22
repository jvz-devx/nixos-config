# Development configuration - Docker, languages, tools
{ pkgs, ... }: {
  # Docker
  virtualisation.docker = {
    enable = true;
    # Rootless mode (more secure, but some compatibility issues)
    # rootless = {
    #   enable = true;
    #   setSocketVariable = true;
    # };
  };

  # NVIDIA Container Toolkit (for --gpus all support)
  hardware.nvidia-container-toolkit.enable = true;

  # GPG agent for signing commits
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Direnv for automatic environment loading
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Git (basic system-wide, detailed config in home-manager)
  programs.git.enable = true;

  # Development packages
   environment.systemPackages = with pkgs; [
     # Editors
      code-cursor-fhs  # Cursor IDE (needs overlay or FHS)
  
     # Nix tools
      nix-index    # nix-locate command
      comma        # Run programs without installing: , program

     # Common CLI
     curl
     wget
     nano
     tree
     unzip
     ripgrep
     zip
     pciutils
     usbutils
     jq  
     openssh
     file
     which
     lsof
     killall
     nano
     btop
     man-pages
     firefox

     # Network Tools
     nmap             # Network scanning and discovery
     mtr              # Network diagnostic tool (traceroute + ping)
     iperf3           # Network performance testing
     speedtest-cli    # Speed testing (CLI)
     tcpdump          # Packet capture and analysis
     wireshark        # GUI packet analyzer
     ethtool          # Ethernet device settings
     bind             # DNS tools (dig, nslookup, host)
     whois            # Domain lookup
     netcat-gnu       # Network utility for reading/writing network connections
     traceroute       # Network path tracing
     iftop            # Bandwidth monitoring (per connection)
     nethogs          # Bandwidth monitoring (per process)
     bandwhich        # Modern bandwidth utilization tool
     inetutils        # telnet, ftp, etc.
     nload            # Network load monitoring
     iptables         # Firewall management
     nftables         # Modern firewall
     wireguard-tools  # WireGuard VPN tools

     # Languages (prefer per-project with devShells/direnv)
      go
#      rustup
      python3
      dotnet-sdk_10
   ];

  # nix-index for command-not-found (enabled)
   programs.nix-index = {
     enable = true;
     enableZshIntegration = true;
   };
}

