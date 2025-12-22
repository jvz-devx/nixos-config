# Hardware configuration - GPU, ASUS, audio, ethernet
{ ... }: {
  imports = [
    ./gpu-mode.nix    # GPU mode selector (dedicated/hybrid/integrated)
    ./nvidia.nix
    ./asus.nix
    ./audio.nix
    ./ethernet.nix
  ];

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}

