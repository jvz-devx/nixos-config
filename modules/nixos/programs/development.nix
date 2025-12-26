# Development configuration - Docker, languages, tools
# Shared development module for all hosts
{ config, lib, pkgs, ... }: {
  options.myConfig.programs.development.enable = lib.mkEnableOption "Development tools (Docker, languages, CLI tools)";

  config = lib.mkIf config.myConfig.programs.development.enable {
    # Docker
    virtualisation.docker.enable = true;

    # NVIDIA Container Toolkit (for --gpus all support)
    # Only enable if NVIDIA hardware is configured (not for ISO builds)
    hardware.nvidia-container-toolkit.enable = lib.mkIf (config.myConfig.hardware.nvidia.enable or false) true;

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
    code-cursor-fhs  # Cursor IDE

    # Nix tools
    nix-index    # nix-locate command
    comma        # Run programs without installing: , program
    sops         # Secrets management CLI
    age          # Modern encryption tool for SOPS

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
    netcat-gnu       # Network utility
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
    python3
    dotnet-sdk_10
    gwe           # GreenWithEnvy - NVIDIA overclocking/underclocking
    nvtopPackages.nvidia # GPU process monitor
    mission-center # Modern Task Manager for Linux
    ];

    # nix-index for command-not-found
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}


