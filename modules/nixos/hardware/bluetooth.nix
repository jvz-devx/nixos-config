# Bluetooth configuration
# Shared bluetooth module for all hosts
{
  config,
  lib,
  ...
}: {
  options.myConfig.hardware.bluetooth.enable = lib.mkEnableOption "Bluetooth support";

  config = lib.mkIf config.myConfig.hardware.bluetooth.enable {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
