# Module index - imports all NixOS modules
# This file makes all modules available to all hosts
{ ... }: {
  imports = [
    # Hardware modules
    ./hardware/amd-cpu.nix
    ./hardware/intel-cpu.nix
    ./hardware/audio.nix
    ./hardware/bluetooth.nix
    ./hardware/nvidia.nix
    ./hardware/nvidia-stability-tweaks.nix
    ./hardware/asus.nix

    # Desktop modules
    ./desktop/plasma.nix
    ./desktop/portals.nix

    # Program modules
    ./programs/gaming.nix
    ./programs/development.nix

    # Service modules
    ./services/tailscale.nix
    ./services/maintenance.nix

    # System modules
    ./system/locale.nix
    ./system/boot.nix
    ./system/boot-laptop.nix
    ./system/disk.nix
    ./system/power.nix
    ./system/iso-support.nix

    # Profiles
    ./profiles/desktop.nix
    ./profiles/gaming.nix
    ./profiles/development.nix
    ./profiles/workstation.nix
    ./profiles/server.nix
  ];
}

