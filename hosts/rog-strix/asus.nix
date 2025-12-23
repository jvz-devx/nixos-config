# ASUS ROG configuration - asusd, supergfxd, ROG controls
{ pkgs, ... }: {
  # ASUS system daemon (fan control, keyboard LEDs, etc.)
  services.asusd = {
    enable = true;
    enableUserService = true;
  };

  # GPU switching daemon (Hybrid/Integrated/dGPU modes)
  services.supergfxd.enable = true;

  # Fix for supergfxd needing lspci
  systemd.services.supergfxd.path = [ pkgs.pciutils ];

  # Power profiles daemon (integrates with asusd)
  services.power-profiles-daemon.enable = true;

  # ROG-specific packages for system control
  environment.systemPackages = with pkgs; [
    asusctl              # CLI for asusd (fan control, keyboard LEDs, etc.)
    supergfxctl          # CLI for supergfxd (GPU mode switching)
  ];
}


