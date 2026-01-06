# Intel CPU configuration
# Microcode updates and Intel-specific settings
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.hardware.cpu.intel.enable = lib.mkEnableOption "Intel CPU support (microcode and kernel modules)";

  config = lib.mkIf config.myConfig.hardware.cpu.intel.enable {
    # Intel microcode updates
    hardware.cpu.intel.updateMicrocode = true;

    # Intel-specific kernel modules
    boot.kernelModules = ["kvm-intel"];
  };
}
