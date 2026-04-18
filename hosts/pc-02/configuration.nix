# Main configuration for pc-02 (Jens' Desktop)
# AMD CPU + NVIDIA GPU desktop
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # Hardware configuration (generate on target machine)
    ./hardware-configuration.nix
  ];

  # Enable profiles and options
  myConfig.profiles.workstation.enable = true;
  myConfig.services.tailscale.enable = true;
  myConfig.services.tailscale.operator = "jens"; # Allow ktailctl GUI to work
  myConfig.services.ssh.enable = true;
  # advertiseExitNode = false (default) allows using Mullvad or other exit nodes via ktailctl
  myConfig.secrets.sshKeyUser = "jens"; # Deploy SSH key to this user

  # Enable ISO support (flake copy, hardware detection)
  myConfig.system.iso.enable = true;
  myConfig.system.iso.hostName = "pc-02";

  # Limit build resource usage (prevents OOM from parallel Rust compiles)
  myConfig.system.buildResources.enable = true;

  # Hardware configuration
  myConfig.hardware.nvidia.enable = true;
  myConfig.hardware.nvidia.isLaptop = false;
  myConfig.hardware.nvidia.driverBranch = "production";
  myConfig.hardware.nvidia.stabilityTweaks.enable = true;
  myConfig.hardware.cpu.amd.enable = true;

  # KDE Remote Desktop (RDP via krdpserver). Shares jens' Plasma session.
  # Password lives in sops (key: krdp_password). Access is restricted to the
  # LAN and Tailscale ranges.
  myConfig.services.krdp = {
    enable = true;
    username = "jens";
    allowedCIDRs = ["192.168.0.0/16" "100.64.0.0/10"];
  };

  # RustDesk remote desktop (LAN + Tailscale only)
  myConfig.programs.rustdesk.client = {
    enable = true;
    serverHost = "192.168.1.112"; # homelab cluster MetalLB IP
    serverKey = "HpSEDKZzog4eXpnWR2Sn2c7pdSIUe+CgbrLFJD1uMsQ=";
    whitelist = ["192.168.0.0/22" "100.64.0.0/10"];
  };
  # server role is intentionally NOT enabled — hbbs/hbbr run in the homelab cluster now.

  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.stable-packages
      inputs.claude-code.overlays.default # Native Claude Code binary
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Nix settings
  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
      trusted-users = ["root" "jens" "@wheel"];
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # Hostname
  networking.hostName = "pc-02";

  # Administrator rights
  security.sudo.wheelNeedsPassword = false;

  # User configuration
  users.users.jens = {
    isNormalUser = true;
    description = "Jens";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "docker"
      "input" # Required for whisper-ptt daemon (evtest key monitoring)
    ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKvQsKbzbW9a3tncPJojcCXLjHg8aBCQCmPQVzzsRXeZ nixos"
    ];
  };

  # Enable zsh system-wide (required for user shell)
  programs.zsh.enable = true;
  programs.git.enable = true;
  programs.git.config.safe.directory = "/etc/nixos";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}
