# Hardware configuration for pc-02
# IMPORTANT: This is a placeholder file!
# Generate the real hardware configuration on the target machine with:
#   sudo nixos-generate-config --show-hardware-config > /etc/nixos/hosts/pc-02/hardware-configuration.nix
#
# Or during installation:
#   nixos-generate-config --root /mnt
#   Then copy /mnt/etc/nixos/hardware-configuration.nix here

{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  # PLACEHOLDER - Replace with actual hardware detection
  # These are example values that should be replaced

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Filesystems - REPLACE THESE WITH YOUR ACTUAL DISK LAYOUT
  # fileSystems."/" = {
  #   device = "/dev/disk/by-uuid/YOUR-ROOT-UUID";
  #   fsType = "btrfs";
  #   options = [ "subvol=@" "compress=zstd" "noatime" ];
  # };
  #
  # fileSystems."/boot" = {
  #   device = "/dev/disk/by-uuid/YOUR-BOOT-UUID";
  #   fsType = "vfat";
  # };
  #
  # swapDevices = [
  #   { device = "/dev/disk/by-uuid/YOUR-SWAP-UUID"; }
  # ];

  # Networking - may be auto-detected
  # networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}


