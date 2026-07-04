# Push-to-talk speech-to-text using whisper.cpp with CUDA
# Hotkey: Super+` (hold to record, release to transcribe)
{
  pkgs,
  lib,
  config,
  ...
}: let
  # Configuration
  modelDir = "${config.home.homeDirectory}/.local/share/whisper";
  modelFile = "ggml-large-v3.bin";
  modelPath = "${modelDir}/${modelFile}";
  recordingDir = "/tmp/whisper-ptt";

  # whisper.cpp with CUDA support
  whisper-cpp-cuda = pkgs.whisper-cpp.override {
    cudaSupport = true;
  };

  # Audio feedback sounds (simple beeps using sox)
  startSound = pkgs.runCommand "start-beep.wav" {} ''
    ${pkgs.sox}/bin/sox -n -r 44100 -c 1 $out synth 0.1 sine 800 vol 0.5
  '';
  stopSound = pkgs.runCommand "stop-beep.wav" {} ''
    ${pkgs.sox}/bin/sox -n -r 44100 -c 1 $out synth 0.1 sine 600 vol 0.5
  '';

  # Main push-to-talk script (triggered by KDE hotkey)
  whisper-ptt = pkgs.writeShellScriptBin "whisper-ptt" ''
    #!/usr/bin/env bash
    set -euo pipefail

    # Configuration
    MODEL_PATH="${modelPath}"
    RECORDING_DIR="${recordingDir}"
    AUDIO_FILE="$RECORDING_DIR/recording.wav"
    PID_FILE="$RECORDING_DIR/recording.pid"
    START_SOUND="${startSound}"
    STOP_SOUND="${stopSound}"

    # Ensure recording directory exists
    mkdir -p "$RECORDING_DIR"

    # Check if model exists
    if [[ ! -f "$MODEL_PATH" ]]; then
      ${pkgs.libnotify}/bin/notify-send -u critical "Whisper PTT" \
        "Model not found!\nRun: whisper-ptt-download-model"
      exit 1
    fi

    start_recording() {
      # Play start sound
      ${pkgs.sox}/bin/play -q "$START_SOUND" 2>/dev/null &

      # Show recording notification
      ${pkgs.libnotify}/bin/notify-send -t 1000 "🎙️ Recording..." "Release Super+\` to transcribe"

      # Start recording with sox (16kHz mono WAV for Whisper)
      ${pkgs.sox}/bin/rec -q -r 16000 -c 1 -b 16 "$AUDIO_FILE" &
      echo $! > "$PID_FILE"
    }

    stop_recording() {
      if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
          kill "$pid" 2>/dev/null || true
          wait "$pid" 2>/dev/null || true
        fi
        rm -f "$PID_FILE"
      fi

      # Play stop sound
      ${pkgs.sox}/bin/play -q "$STOP_SOUND" 2>/dev/null &

      # Show processing notification
      ${pkgs.libnotify}/bin/notify-send -t 2000 "⏳ Transcribing..." "Processing with Whisper"
    }

    transcribe() {
      if [[ ! -f "$AUDIO_FILE" ]]; then
        ${pkgs.libnotify}/bin/notify-send -u critical "Whisper PTT" "No recording found!"
        exit 1
      fi

      # Run whisper.cpp with CUDA
      # Output format: writes to $AUDIO_FILE.txt when using --output-txt
      local output_file="$AUDIO_FILE.txt"
      rm -f "$output_file"

      ${whisper-cpp-cuda}/bin/whisper-cpp \
        --model "$MODEL_PATH" \
        --file "$AUDIO_FILE" \
        --language auto \
        --no-timestamps \
        --output-txt \
        --output-file "$RECORDING_DIR/recording" \
        2>/dev/null

      # Clean up audio file
      rm -f "$AUDIO_FILE"

      # Read result from output file
      local result=""
      if [[ -f "$output_file" ]]; then
        # Clean up the text: remove leading/trailing whitespace and [BLANK_AUDIO] markers
        result=$(cat "$output_file" | \
          sed 's/\[BLANK_AUDIO\]//g' | \
          sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | \
          tr -s ' ' | \
          sed '/^$/d')
        rm -f "$output_file"
      fi

      if [[ -z "$result" ]]; then
        ${pkgs.libnotify}/bin/notify-send -t 3000 "Whisper PTT" "No speech detected"
        exit 0
      fi

      # Copy to clipboard
      echo -n "$result" | ${pkgs.wl-clipboard}/bin/wl-copy

      # Type the text at cursor position using ydotool (works on Wayland)
      ${pkgs.ydotool}/bin/ydotool type --key-delay 0 -- "$result"

      # Show success notification (truncate long text)
      local display_text="$result"
      if [[ ''${#result} -gt 100 ]]; then
        display_text="''${result:0:100}..."
      fi
      ${pkgs.libnotify}/bin/notify-send -t 3000 "Transcribed" "$display_text"
    }

    # Main logic based on argument
    case "''${1:-}" in
      start)
        start_recording
        ;;
      stop)
        stop_recording
        transcribe
        ;;
      toggle)
        # Toggle mode for fallback (single key press)
        if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
          stop_recording
          transcribe
        else
          start_recording
        fi
        ;;
      *)
        echo "Usage: whisper-ptt {start|stop|toggle}"
        echo ""
        echo "  start  - Start recording"
        echo "  stop   - Stop recording and transcribe"
        echo "  toggle - Toggle recording on/off (for single-key mode)"
        exit 1
        ;;
    esac
  '';

  # Model download helper script
  whisper-ptt-download-model = pkgs.writeShellScriptBin "whisper-ptt-download-model" ''
    #!/usr/bin/env bash
    set -euo pipefail

    MODEL_DIR="${modelDir}"
    MODEL_FILE="${modelFile}"
    MODEL_PATH="$MODEL_DIR/$MODEL_FILE"
    MODEL_URL="https://huggingface.co/ggerganov/whisper.cpp/resolve/main/$MODEL_FILE"

    mkdir -p "$MODEL_DIR"

    if [[ -f "$MODEL_PATH" ]]; then
      echo "Model already exists at: $MODEL_PATH"
      echo "Size: $(du -h "$MODEL_PATH" | cut -f1)"
      exit 0
    fi

    echo "Downloading Whisper large-v3 model (~3GB)..."
    echo "URL: $MODEL_URL"
    echo "Destination: $MODEL_PATH"
    echo ""

    ${pkgs.curl}/bin/curl -L --progress-bar -o "$MODEL_PATH" "$MODEL_URL"

    echo ""
    echo "Download complete!"
    echo "Model saved to: $MODEL_PATH"
    echo "Size: $(du -h "$MODEL_PATH" | cut -f1)"
  '';

  # Push-to-talk daemon that monitors key events
  # This daemon listens for Super+` press/release to trigger recording
  whisper-ptt-daemon = pkgs.writeShellScriptBin "whisper-ptt-daemon" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Whisper PTT Daemon starting..."
    echo "Hotkey: Super+\` (hold to record, release to transcribe)"

    # Find keyboard device from /proc/bus/input/devices
    find_keyboard() {
      local handler
      handler=$(grep -A4 -i "keyboard" /proc/bus/input/devices 2>/dev/null | \
                grep -oP 'event\d+' | head -1)
      if [[ -n "$handler" ]]; then
        echo "/dev/input/$handler"
        return 0
      fi
      return 1
    }

    KEYBOARD_DEV=$(find_keyboard)
    if [[ -z "$KEYBOARD_DEV" ]]; then
      echo "Error: No keyboard device found"
      echo "Make sure you're in the 'input' group: sudo usermod -aG input $USER"
      exit 1
    fi

    echo "Using keyboard device: $KEYBOARD_DEV"

    # Key codes
    KEY_LEFTMETA=125  # Super/Meta key
    KEY_GRAVE=41      # Backtick key

    # State tracking
    META_PRESSED=false
    GRAVE_PRESSED=false
    RECORDING=false

    # Monitor key events
    ${pkgs.evtest}/bin/evtest "$KEYBOARD_DEV" 2>/dev/null | while read -r line; do
      # Parse event: type 1 (EV_KEY), code, value (1=press, 0=release)
      if [[ "$line" =~ type\ 1\ \(EV_KEY\),\ code\ ([0-9]+).*value\ ([0-9]+) ]]; then
        code="''${BASH_REMATCH[1]}"
        value="''${BASH_REMATCH[2]}"

        # Track Meta key state
        if [[ "$code" == "$KEY_LEFTMETA" ]]; then
          if [[ "$value" == "1" ]]; then
            META_PRESSED=true
          else
            META_PRESSED=false
            # If we were recording and Meta is released, stop
            if [[ "$RECORDING" == "true" ]]; then
              RECORDING=false
              ${whisper-ptt}/bin/whisper-ptt stop &
            fi
          fi
        fi

        # Track Grave (backtick) key state
        if [[ "$code" == "$KEY_GRAVE" ]]; then
          if [[ "$value" == "1" && "$META_PRESSED" == "true" && "$RECORDING" == "false" ]]; then
            # Super+` pressed - start recording
            RECORDING=true
            GRAVE_PRESSED=true
            ${whisper-ptt}/bin/whisper-ptt start &
          elif [[ "$value" == "0" && "$GRAVE_PRESSED" == "true" ]]; then
            # Backtick released - stop recording if we were recording
            GRAVE_PRESSED=false
            if [[ "$RECORDING" == "true" ]]; then
              RECORDING=false
              ${whisper-ptt}/bin/whisper-ptt stop &
            fi
          fi
        fi
      fi
    done
  '';
in {
  home.packages = [
    # Core tools
    whisper-cpp-cuda
    pkgs.sox # Audio recording
    pkgs.ydotool # Text typing on Wayland
    pkgs.wl-clipboard # Clipboard access
    pkgs.libnotify # Notifications
    pkgs.evtest # Key event monitoring
    pkgs.curl # Model download

    # Custom scripts
    whisper-ptt
    whisper-ptt-download-model
    whisper-ptt-daemon
  ];

  # Systemd user service for the PTT daemon
  systemd.user.services.whisper-ptt-daemon = {
    Unit = {
      Description = "Whisper Push-to-Talk Daemon";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${whisper-ptt-daemon}/bin/whisper-ptt-daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };

  # Note: ydotool daemon is managed by NixOS via programs.ydotool.enable = true
  # in modules/nixos/profiles/desktop.nix (runs as system service with proper uinput access)
}
