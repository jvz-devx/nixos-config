# Development configuration - Docker, languages, tools
# Shared development module for all hosts
{ config, lib, pkgs, ... }: {
  options.myConfig.programs.development.enable = lib.mkEnableOption "Development tools (Docker, languages, CLI tools)";

  config = lib.mkIf config.myConfig.programs.development.enable {
    # Docker
    virtualisation.docker.enable = true;

    # NVIDIA Container Toolkit (for --gpus all support)
    # Only enable if NVIDIA hardware is configured AND not in integrated mode
    hardware.nvidia-container-toolkit.enable = let
      cfg = config.myConfig.hardware.nvidia;
      isLaptop = cfg.isLaptop or false;
      gpuMode = cfg.mode or (if isLaptop then "dedicated" else "desktop");
    in (cfg.enable or false) && gpuMode != "integrated";

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
    environment.systemPackages = with pkgs; let
      cfg = config.myConfig.hardware.nvidia;
      isLaptop = cfg.isLaptop or false;
      gpuMode = cfg.mode or (if isLaptop then "dedicated" else "desktop");
      isIntegrated = gpuMode == "integrated";
    in [
    # Editors
    code-cursor-fhs  # Cursor IDE

    # Nix tools
    nix-index    # nix-locate command
    comma        # Run programs without installing: , program
    sops         # Secrets management CLI
    age          # Modern encryption tool for SOPS
    nix-tree     # Visualize Nix store
    nix-diff     # Compare Nix derivations
    nix-output-monitor # Colorize nix-build output
    deadnix      # Detect dead code in Nix
    statix       # Nix linter

    # Common CLI
    curl
    wget
    nano
    tree
    unzip
    p7zip
    ripgrep
    fd            # Faster, more intuitive find
    bat           # Better cat with syntax highlighting
    eza           # Modern replacement for ls
    fzf           # Fuzzy finder - indispensable
    ncdu          # Interactive disk usage browser
    ripgrep-all   # Search in PDFs, archives, etc.
    rsync         # File synchronization tool
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

    # Git Tools
    gh              # GitHub CLI - essential
    lazygit         # Amazing TUI git interface
    tig             # Text-mode interface for git
    git-lfs         # Large File Storage support

    # Languages (prefer per-project with devShells/direnv)
    go
    python3
    uv             # Python package manager
    sqlit-tui      # User friendly TUI for SQL databases
    dotnet-sdk_10
    rustc          # Rust compiler
    cargo          # Rust package manager
    rust-analyzer  # Rust LSP
    clang          # C/C++ compiler
    llvm           # LLVM toolchain

    # DevOps
    lazydocker     # TUI for Docker management
    kubectl        # Kubernetes CLI
    k9s            # Kubernetes TUI

    # System Monitoring
    glances        # Cross-platform system monitoring
    iotop          # I/O monitoring
    s-tui          # Stress TUI
    stress-ng      # System stress testing
    lm_sensors     # Hardware sensors
    mission-center # Modern Task Manager for Linux
    ] ++ lib.optionals (!isIntegrated) [
      gwe            # GreenWithEnvy - NVIDIA overclocking/underclocking
      nvtopPackages.nvidia # GPU process monitor
    ] ++ lib.optionals (isIntegrated) [
      nvtopPackages.intel # GPU process monitor for Intel
    ] ++ [
    # Databases
    postgresql     # PostgreSQL server
    redis          # Redis server
    ];

    # nix-index for command-not-found
    programs.nix-index = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}


