{pkgs, ...}: let
  power-profile-toggle = pkgs.writeShellApplication {
    name = "power-profile-toggle";
    runtimeInputs = [
      pkgs.libnotify
      pkgs.power-profiles-daemon
    ];
    text = ''
      set -euo pipefail

      current="$(powerprofilesctl get 2>/dev/null || true)"

      case "$current" in
        power-saver)
          next="balanced"
          label="Balanced"
          ;;
        balanced)
          next="performance"
          label="Performance"
          ;;
        performance)
          next="power-saver"
          label="Power Saver"
          ;;
        *)
          next="balanced"
          label="Balanced"
          ;;
      esac

      powerprofilesctl set "$next"
      notify-send "Power profile" "$label"
      printf '%s\n' "$next"
    '';
  };
in {
  home.packages = [
    power-profile-toggle
  ];
}
