# Audio configuration - Pipewire, ALSA, rtkit
{ ... }: {
  # Disable PulseAudio (replaced by Pipewire)
  services.pulseaudio.enable = false;

  # Enable real-time audio priority
  security.rtkit.enable = true;

  # Pipewire
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    pulse.enable = true;
    jack.enable = true;
    wireplumber.enable = true;

    # Low-latency configuration for gaming
    # Quantum 64 is a good balance between low latency and stability
    # If you experience audio glitches, increase to 128
    # For even lower latency (if your system can handle it), decrease to 32
    extraConfig.pipewire."92-low-latency" = {
      context.properties = {
        default.clock.rate = 48000;
        default.clock.quantum = 64;
        default.clock.min-quantum = 64;
        default.clock.max-quantum = 64;
      };
    };
  };
}

