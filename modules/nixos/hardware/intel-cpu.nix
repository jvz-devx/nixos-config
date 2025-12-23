# Intel CPU configuration
# Microcode updates and Intel-specific settings
{ pkgs, ... }: {
  # Intel microcode updates
  hardware.cpu.intel.updateMicrocode = true;

  # Intel-specific kernel modules
  boot.kernelModules = [ "kvm-intel" ];
}


