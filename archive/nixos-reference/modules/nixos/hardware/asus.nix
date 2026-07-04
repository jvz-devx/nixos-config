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

    # Limit battery charge to 80% to reduce wear
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{charge_control_end_threshold}=="[0-9]*", ATTR{charge_control_end_threshold}="80"
    '';

    # GPU switching daemon (Hybrid/Integrated/dGPU modes)
    services.supergfxd.enable = true;

    # Fix for supergfxd needing lspci
    systemd.services.supergfxd.path = [pkgs.pciutils];

    # Power profiles daemon (integrates with asusd, Fn key switching)
    services.power-profiles-daemon.enable = true;

    # ROG-specific packages for system control
    environment.systemPackages = with pkgs; [
      asusctl # CLI for asusd (fan control, keyboard LEDs, etc.)
      supergfxctl # CLI for supergfxd (GPU mode switching)
    ];

    # Audio fixes for ASUS ROG laptops
    # Modern ROG laptops (Raptor Lake+) use SOF and often need to force the driver
    boot.extraModprobeConfig = ''
      # Force SOF driver (required for internal speakers on G614)
      options snd-intel-dspcfg dsp_driver=3

      # NOTE: Manual card indexing (options snd-hda-intel index=1,0) was removed
      # as it causes "cannot find the slot" errors with NVIDIA 590+ drivers.
      # Modern PipeWire/WirePlumber handles indexing dynamically.

      # NOTE: hda_model=asus-zenbook was removed as it is ignored by SOF
      # and is only relevant for legacy HDA drivers.
    '';

    # Blacklist the AVS driver which can conflict with SOF on Raptor Lake
    boot.blacklistedKernelModules = ["snd_soc_avs"];
  };
}
