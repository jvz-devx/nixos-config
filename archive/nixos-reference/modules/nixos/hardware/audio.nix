# Audio configuration - PipeWire, ALSA, rtkit
# Shared audio module for all hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.hardware.audio.enable = lib.mkEnableOption "Audio support (PipeWire, ALSA, rtkit)";

  config = lib.mkIf config.myConfig.hardware.audio.enable {
    # Disable PulseAudio (replaced by PipeWire)
    services.pulseaudio.enable = false;

    # Enable real-time audio priority
    security.rtkit.enable = true;

    # Required for modern laptop speakers (SOF firmware)
    hardware.enableRedistributableFirmware = true;

    # System packages for audio debugging
    environment.systemPackages = with pkgs; [
      alsa-utils
      pavucontrol
    ];

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

      # Bluetooth codec support. LDAC is omitted: pipewire's LDAC encoder
      # fails to init against WH-1000XM6 (LDACBT_ERR_FATAL) and wireplumber
      # does not fall back, leaving the device stuck at profile=off. AAC is
      # preferred on Sony headsets anyway.
      wireplumber.extraConfig."11-bluetooth-policy" = {
        "monitor.bluez.properties" = {
          "bluez5.enable-sbc-xq" = true;
          "bluez5.enable-msbc" = true;
          "bluez5.enable-hw-volume" = true;
          "bluez5.codecs" = ["sbc" "sbc_xq" "aac"];
          "bluez5.roles" = ["a2dp_sink" "a2dp_source" "bap_sink" "bap_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag"];
        };
      };

      wireplumber.extraConfig."12-bluetooth-codec-quality" = {
        "monitor.bluez.rules" = [
          {
            matches = [{"device.name" = "~bluez_card.*";}];
            actions = {
              update-props = {
                "bluez5.a2dp.aac.bitratemode" = 5;
                "bluez5.auto-connect" = ["hfp_hf" "hsp_hs" "a2dp_sink"];
                "bluez5.hw-volume" = ["hfp_hf" "hsp_hs" "a2dp_sink" "hfp_ag" "hsp_ag" "a2dp_source"];
              };
            };
          }
        ];
      };

      # Stable audio configuration with adaptive latency
      extraConfig.pipewire."92-low-latency" = {
        context.properties = {
          default.clock.rate = 48000;
          default.clock.quantum = 512;
          default.clock.min-quantum = 128;
          default.clock.max-quantum = 2048;
        };
      };
    };

    # pipewire/wireplumber run as user services; `nixos-rebuild switch` only
    # touches system services, so audio config changes require a manual
    # `systemctl --user restart` or a logout to take effect. Restart the user
    # audio stack for every active login session on activation so rebuilds
    # are actually live.
    system.activationScripts.restartUserPipewire = {
      deps = ["users"];
      text = ''
        for dir in /run/user/*; do
          [ -S "$dir/bus" ] || continue
          uid=$(${pkgs.coreutils}/bin/basename "$dir")
          XDG_RUNTIME_DIR="$dir" DBUS_SESSION_BUS_ADDRESS="unix:path=$dir/bus" \
            ${pkgs.util-linux}/bin/runuser -u "#$uid" -- \
            ${pkgs.systemd}/bin/systemctl --user --no-block try-restart \
              wireplumber.service pipewire.service pipewire-pulse.service 2>/dev/null || true
        done
      '';
    };
  };
}
