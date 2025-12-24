# Main configuration for server-01 (Headless Server)
# General purpose server with Docker, Tailscale, and essential tools
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  imports = [
    # Hardware configuration (will be auto-generated on first boot if missing)
    ./hardware-configuration.nix
  ];

  # Enable server profile
  myConfig.profiles.server.enable = true;

  # Nixpkgs configuration
  nixpkgs = {
    overlays = [
      inputs.self.overlays.additions
      inputs.self.overlays.modifications
      inputs.self.overlays.stable-packages
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
      trusted-users = [ "root" "admin" "@wheel" ];
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # Hostname
  networking.hostName = "server-01";

  # Administrator rights
  security.sudo.wheelNeedsPassword = false;

  # User configuration
  users.users.admin = {
    isNormalUser = true;
    description = "Administrator";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  # Enable zsh system-wide (required for user shell)
  programs.zsh.enable = true;
  programs.git.enable = true;
  programs.git.config.safe.directory = "/etc/nixos";

  # SSH server
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = true;  # Can be disabled after setting up SSH keys
    };
  };

  # Auto-generate hardware-configuration.nix on first boot if it doesn't exist
  systemd.services.generate-hardware-config = {
    description = "Generate hardware-configuration.nix if missing";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = let
      hardwareConfig = "/etc/nixos/hosts/server-01/hardware-configuration.nix";
    in ''
      # Check if hardware-configuration.nix has actual hardware detection (fileSystems, etc.)
      if ! grep -q "fileSystems" "${hardwareConfig}" 2>/dev/null || grep -q "# Auto-detection:" "${hardwareConfig}" 2>/dev/null; then
        echo "Hardware configuration needs generation. Generating..."
        cd /etc/nixos
        ${pkgs.nixos}/bin/nixos-generate-config --show-hardware-config > "${hardwareConfig}" || true
        echo "Hardware configuration generated at ${hardwareConfig}"
        echo "Please review the file, then rebuild: sudo nixos-rebuild switch --flake '.#server-01'"
      else
        echo "Hardware configuration already exists with detected hardware."
      fi
    '';
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}

