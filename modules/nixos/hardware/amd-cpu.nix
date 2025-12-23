# AMD CPU configuration
# Microcode updates and AMD-specific settings
{ pkgs, ... }: {
  # AMD microcode updates
  hardware.cpu.amd.updateMicrocode = true;

  # AMD-specific kernel modules (loaded automatically, but explicit is fine)
  boot.kernelModules = [ "kvm-amd" ];
}


