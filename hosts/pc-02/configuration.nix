# Main configuration for pc-02 (Lisa's Desktop)
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

    # Shared NixOS modules
    ../../modules/nixos/desktop/plasma.nix
    ../../modules/nixos/desktop/portals.nix
    ../../modules/nixos/hardware/nvidia-desktop.nix
    ../../modules/nixos/hardware/amd-cpu.nix
    ../../modules/nixos/hardware/audio.nix
    ../../modules/nixos/hardware/bluetooth.nix
    ../../modules/nixos/programs/gaming.nix
    ../../modules/nixos/programs/development.nix
    ../../modules/nixos/services/maintenance.nix
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/system/locale.nix
    ../../modules/nixos/system/boot.nix
    ../../modules/nixos/system/disk.nix
  ];

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
    };
    channel.enable = false;
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  # Hostname
  networking.hostName = "pc-02";

  # User configuration
  users.users.lisa = {
    isNormalUser = true;
    description = "Lisa";
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "video"
      "audio"
      "docker"
    ];
  };

  # Enable zsh system-wide (required for user shell)
  programs.zsh.enable = true;

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";
}

