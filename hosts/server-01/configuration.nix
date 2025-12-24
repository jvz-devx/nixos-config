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

  # Copy flake source to /etc/nixos in the ISO/installed system
  # This ensures the flake is available for rebuilding after installation
  system.activationScripts.copy-flake = let
    # Reference the flake root (two levels up from this config file)
    flakeRoot = builtins.path {
      path = ../../.;
      filter = path: type:
        type == "regular" || type == "directory";
    };
  in ''
    if [ ! -d /etc/nixos/.git ] && [ -d ${toString flakeRoot} ]; then
      echo "Copying flake source to /etc/nixos..."
      mkdir -p /etc/nixos
      # Use rsync if available, otherwise cp
      if command -v rsync >/dev/null 2>&1; then
        rsync -a --exclude='.git' ${toString flakeRoot}/ /etc/nixos/ || true
      else
        cp -r ${toString flakeRoot}/* /etc/nixos/ 2>/dev/null || true
      fi
      chmod -R u+w /etc/nixos
      echo "Flake source copied to /etc/nixos"
    fi
  '';

  # Auto-generate hardware-configuration.nix on first boot if it doesn't exist
  systemd.services.generate-hardware-config = {
    description = "Generate hardware-configuration.nix if missing";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    path = with pkgs; [ nixos-install-tools ];
    script = let
      hardwareConfig = "/etc/nixos/hosts/server-01/hardware-configuration.nix";
    in ''
      # Check if hardware-configuration.nix has actual hardware detection (fileSystems, etc.)
      if ! grep -q "fileSystems" "${hardwareConfig}" 2>/dev/null || grep -q "# Auto-detection:" "${hardwareConfig}" 2>/dev/null; then
        echo "Hardware configuration needs generation. Generating..."
        cd /etc/nixos
        nixos-generate-config --show-hardware-config > "${hardwareConfig}" || true
        echo "Hardware configuration generated at ${hardwareConfig}"
        echo "Please review the file, then rebuild: sudo nixos-rebuild switch --flake '.#server-01'"
      else
        echo "Hardware configuration already exists with detected hardware."
      fi
    '';
  };

  # ISO image configuration (only used when building ISO)
  isoImage = {
    isoName = "server-01-${config.system.nixos.label}-${pkgs.stdenv.hostPlatform.system}.iso";
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}

