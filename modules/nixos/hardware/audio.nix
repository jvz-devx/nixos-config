# Audio configuration - PipeWire, ALSA, rtkit
# Shared audio module for all hosts
{ config, lib, ... }: {
  options.myConfig.hardware.audio.enable = lib.mkEnableOption "Audio support (PipeWire, ALSA, rtkit)";

  config = lib.mkIf config.myConfig.hardware.audio.enable {
    # Disable PulseAudio (replaced by PipeWire)
    services.pulseaudio.enable = false;

    # Enable real-time audio priority
    security.rtkit.enable = true;

    # Required for modern laptop speakers (SOF firmware)
    hardware.enableRedistributableFirmware = true;
    hardware.sof-firmware.enable = true;

    # PipeWire
    services.pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;

      # Stable audio configuration with adaptive latency
      extraConfig.pipewire."92-low-latency" = {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.quantum = 128;
          default.clock.min-quantum = 64;
          default.clock.max-quantum = 2048;
        };
      };
    };
  };
}


