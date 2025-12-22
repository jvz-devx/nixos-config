# Ethernet configuration - Realtek RTL8125 2.5GbE
{ config, ... }: {
  # Use official Realtek r8125 driver instead of the generic r8169
  # r8125 provides better performance and stability for RTL8125 2.5GbE controllers
  boot.extraModulePackages = with config.boot.kernelPackages; [ r8125 ];
  
  # Blacklist the generic r8169 driver to prevent conflicts
  # r8169 has known issues with RTL8125: poor upload speeds, latency spikes, and connection drops
  boot.blacklistedKernelModules = [ "r8169" ];
  
  # Explicitly load the r8125 driver at boot
  boot.kernelModules = [ "r8125" ];
}


