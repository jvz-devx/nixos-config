# ISO Support Module - shared configuration for all ISO builds
# Provides: flake source copying, hardware detection, ISO naming
{ config, lib, pkgs, options, ... }:

let
  cfg = config.myConfig.system.iso;
in {
  options.myConfig.system.iso = {
    enable = lib.mkEnableOption "ISO support (flake copy, hardware detection)";
    
    autologin = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable autologin for the nixos user (use for ISO builds only)";
    };

    hostName = lib.mkOption {
      type = lib.types.str;
      description = "The hostname for this configuration (used in hardware config path)";
    };
    
    hardwareConfigPath = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos/hosts/${cfg.hostName}/hardware-configuration.nix";
      description = "Path to the hardware-configuration.nix file";
    };
  };

  config = lib.mkIf cfg.enable {
      # ISO-specific user and autologin (only when autologin is enabled)
      users.users.nixos = lib.mkIf cfg.autologin {
        isNormalUser = true;
        extraGroups = [ "wheel" "networkmanager" "video" ];
        initialPassword = "TEMP_ISO_PASSWORD"; # Replaced by create_server_iso.sh
      };
    # Force US keyboard for ISO environment (avoids Dutch layout confusion during install)
    console.keyMap = lib.mkForce "us";
    services.xserver.xkb.layout = lib.mkForce "us";
    services.xserver.xkb.variant = lib.mkForce "";


    services.getty.autologinUser = lib.mkIf cfg.autologin "nixos";

    # Copy flake source to /etc/nixos in the ISO/installed system
    # This ensures the flake is available for rebuilding after installation
    system.activationScripts.copy-flake = let
      # Reference the flake root (three levels up from this module file)
      flakeRoot = builtins.path {
        path = ../../../.;
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
      script = ''
        # Check if hardware-configuration.nix has actual hardware detection (fileSystems, etc.)
        if ! grep -q "fileSystems" "${cfg.hardwareConfigPath}" 2>/dev/null || grep -q "# Auto-detection:" "${cfg.hardwareConfigPath}" 2>/dev/null; then
          echo "Hardware configuration needs generation. Generating..."
          cd /etc/nixos
          nixos-generate-config --show-hardware-config > "${cfg.hardwareConfigPath}" || true
          echo "Hardware configuration generated at ${cfg.hardwareConfigPath}"
          echo "Please review the file, then rebuild: sudo nixos-rebuild switch --flake '.#${cfg.hostName}'"
        else
          echo "Hardware configuration already exists with detected hardware."
        fi
      '';
    };
  };
}

