# AMD CPU configuration
# Microcode updates and AMD-specific settings
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.hardware.cpu.amd.enable = lib.mkEnableOption "AMD CPU support (microcode and kernel modules)";

  config = lib.mkIf config.myConfig.hardware.cpu.amd.enable {
    # AMD microcode updates
    hardware.cpu.amd.updateMicrocode = true;

    # AMD-specific kernel modules (loaded automatically, but explicit is fine)
    boot.kernelModules = ["kvm-amd"];
  };
}
