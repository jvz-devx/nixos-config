# ASUS ROG configuration - asusd, supergfxd, ROG controls
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.hardware.asus.enable = lib.mkEnableOption "ASUS ROG laptop support (asusd, supergfxd)";

  config = lib.mkIf config.myConfig.hardware.asus.enable {
    # ASUS system daemon (fan control, keyboard LEDs, etc.)
    services.asusd = {
      enable = true;
      enableUserService = true;
    };

    # GPU switching daemon (Hybrid/Integrated/dGPU modes)
    services.supergfxd.enable = true;

    # Fix for supergfxd needing lspci
    systemd.services.supergfxd.path = [pkgs.pciutils];

    # Power profiles daemon (integrates with asusd)
    services.power-profiles-daemon.enable = true;

    # ROG-specific packages for system control
    environment.systemPackages = with pkgs; [
      asusctl # CLI for asusd (fan control, keyboard LEDs, etc.)
      supergfxctl # CLI for supergfxd (GPU mode switching)
    ];

    # Audio fixes for ASUS ROG laptops
    # Modern ROG laptops (Raptor Lake+) use SOF and often need to force the driver
    boot.extraModprobeConfig = ''
      # Force SOF driver
      options snd-intel-dspcfg dsp_driver=3
      # Fix for Cirrus Logic amplifiers and SoundWire
      options snd-sof-intel-hda-common hda_model=asus-zenbook
      options snd-hda-intel index=1,0
    '';

    # Blacklist the AVS driver which can conflict with SOF on Raptor Lake
    boot.blacklistedKernelModules = ["snd_soc_avs"];
  };
}
