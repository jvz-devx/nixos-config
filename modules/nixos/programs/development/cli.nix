# Development CLI tools and languages
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.myConfig.programs.development.enable {
    environment.systemPackages = with pkgs; let
      hasNvidia = config.myConfig.hardware.nvidia.enable or false;
      hasIntel = config.myConfig.hardware.cpu.intel.enable or false;
      hasAmd = config.myConfig.hardware.cpu.amd.enable or false;
    in
      [
        # Nix tools
        nix-index # nix-locate command
        comma # Run programs without installing: , program
        sops # Secrets management CLI
        age # Modern encryption tool for SOPS
        nix-tree # Visualize Nix store
        nix-diff # Compare Nix derivations
        nix-output-monitor # Colorize nix-build output
        deadnix # Detect dead code in Nix
        statix # Nix linter

        # Common CLI
        curl
        wget
        nano
        tree
        unzip
        p7zip
        ripgrep
        fd # Faster, more intuitive find
        bat # Better cat with syntax highlighting
        eza # Modern replacement for ls
        fzf # Fuzzy finder - indispensable
        ncdu # Interactive disk usage browser
        ripgrep-all # Search in PDFs, archives, etc.
        rsync # File synchronization tool
        zip
        pciutils
        usbutils
        parted # Disk partitioning tool
        dosfstools # FAT filesystem tools
        btrfs-progs # Btrfs filesystem tools
        jq
        openssh
        file
        which
        lsof
        killall
        btop
        man-pages
        fastfetch # Modern neofetch replacement

        # Network Tools
        nmap # Network scanning and discovery
        mtr # Network diagnostic tool (traceroute + ping)
        iperf3 # Network performance testing
        speedtest-cli # Speed testing (CLI)
        tcpdump # Packet capture and analysis
        ethtool # Ethernet device settings
        bind # DNS tools (dig, nslookup, host)
        whois # Domain lookup
        netcat-gnu # Network utility
        traceroute # Network path tracing
        iftop # Bandwidth monitoring (per connection)
        nethogs # Bandwidth monitoring (per process)
        bandwhich # Modern bandwidth utilization tool
        inetutils # telnet, ftp, etc.
        nload # Network load monitoring
        iptables # Firewall management
        nftables # Modern firewall
        wireguard-tools # WireGuard VPN tools

        # Git Tools
        gh # GitHub CLI - essential
        lazygit # Amazing TUI git interface
        tig # Text-mode interface for git
        git-lfs # Large File Storage support

        # Languages (prefer per-project with devShells/direnv)
        go
        python3
        uv # Python package manager
        sqlit-tui # User friendly TUI for SQL databases
        dotnet-sdk_10
        rustc # Rust compiler
        cargo # Rust package manager
        rust-analyzer # Rust LSP
        clang # C/C++ compiler
        llvm # LLVM toolchain

        # DevOps
        lazydocker # TUI for Docker management
        kubectl # Kubernetes CLI
        k9s # Kubernetes TUI

        # System Monitoring
        glances # Cross-platform system monitoring
        iotop # I/O monitoring
        s-tui # Stress TUI
        stress-ng # System stress testing
        lm_sensors # Hardware sensors

        # Databases
        postgresql # PostgreSQL server
        redis # Redis server
      ]
      ++ lib.optionals hasNvidia [
        nvtopPackages.nvidia # GPU process monitor for NVIDIA
      ]
      ++ lib.optionals (hasIntel && !hasNvidia) [
        nvtopPackages.intel # GPU process monitor for Intel (only if no NVIDIA)
      ]
      ++ lib.optionals (hasAmd && !hasNvidia) [
        nvtopPackages.amd # GPU process monitor for AMD (only if no NVIDIA)
      ];
  };
}
