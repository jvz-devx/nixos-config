# Bluetooth configuration
# Shared bluetooth module for all hosts
{ ... }: {
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
}


