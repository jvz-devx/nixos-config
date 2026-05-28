{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  hyprlandCfg = osConfig.myConfig.desktop.hyprland or {};
  cfgEnabled = hyprlandCfg.enable or false;
  terminalCommand = hyprlandCfg.terminal or "warp-terminal";
  browserCommand = hyprlandCfg.browserCommand or "google-chrome-stable || google-chrome";
  hyprlandPackage = osConfig.programs.hyprland.package or pkgs.hyprland;
  themeStateDir = "${config.home.homeDirectory}/.cache/hypr-theme";

  hypr-shell-start = pkgs.writeShellApplication {
    name = "hypr-shell-start";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.procps
      pkgs.waybar
    ];
    text = ''
      set -euo pipefail

      pkill -x waybar 2>/dev/null || true
      pkill -x .waybar-wrapped 2>/dev/null || true
      nohup waybar >/tmp/waybar-hyprland.log 2>&1 &
    '';
  };

  hypr-kwallet-start = pkgs.writeShellApplication {
    name = "hypr-kwallet-start";
    runtimeInputs = [
      pkgs.qt6.qttools
    ];
    text = ''
      set -euo pipefail

      # Plasma starts KWallet for us; a bare Hyprland session needs to
      # DBus-activate it so PAM-unlocked wallets are available to git/gh.
      qdbus org.kde.kwalletd6 /modules/kwalletd6 org.kde.KWallet.isEnabled >/dev/null 2>&1 || true
    '';
  };

  hypr-status = pkgs.writeShellApplication {
    name = "hypr-status";
    runtimeInputs = [
      pkgs.bluez
      pkgs.coreutils
      pkgs.gawk
      pkgs.gnugrep
      pkgs.networkmanager
      pkgs.wireplumber
    ];
    text = ''
      set -euo pipefail

      case "''${1:-}" in
        volume)
          output="$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || true)"
          if [[ -z "$output" ]]; then
            printf 'Vol --\n'
          elif [[ "$output" == *MUTED* ]]; then
            printf 'Muted\n'
          else
            value="$(awk '{ printf "%.0f", $2 * 100 }' <<< "$output")"
            printf 'Vol %s%%\n' "$value"
          fi
          ;;
        network)
          nmcli -t -f TYPE,STATE,CONNECTION device status 2>/dev/null \
            | awk -F: '
              $2 ~ /^connected/ && $1 != "loopback" && $1 != "bridge" {
                label = $3
                if (label == "") label = $1
                if (length(label) > 14) label = substr(label, 1, 13) ".."
                print label
                found = 1
                exit
              }
              END {
                if (!found) print "Offline"
              }'
          ;;
        bluetooth)
          if timeout 1 bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
            connected="$(timeout 1 bluetoothctl devices Connected 2>/dev/null | wc -l | tr -d ' ')"
            if [[ "$connected" == "0" ]]; then
              printf 'BT on\n'
            else
              printf 'BT %s\n' "$connected"
            fi
          else
            printf 'BT off\n'
          fi
          ;;
        *)
          exit 2
          ;;
      esac
    '';
  };

  hypr-shortcuts = pkgs.writeShellApplication {
    name = "hypr-shortcuts";
    runtimeInputs = [
      pkgs.fuzzel
      pkgs.wl-clipboard
      hyprlandPackage
    ];
    text = ''
      set -euo pipefail

      shortcut_list() {
        printf '%s\n' \
          'Super + Return          Open terminal' \
          'Super + Space           Open app launcher' \
          'Super + /               Show this shortcut picker' \
          'Super + F1              Show this shortcut picker' \
          'Super + B               Open browser' \
          'Super + W               Pick wallpaper and recolor desktop' \
          'Super + Shift + W       Random wallpaper and recolor desktop' \
          'Super + E               Open file manager' \
          'Super + F               Toggle fullscreen' \
          'Super + Shift + Space   Toggle floating' \
          'Super + R               Reload Hyprland config' \
          'Super + Ctrl + L        Lock screen' \
          'Super + N               Notifications' \
          'Super + V               Clipboard history' \
          'Super + Shift + V       Clear clipboard history' \
          'Super + C               Pick color to clipboard' \
          'Super + Ctrl + B        Restart Waybar' \
          'Super + Shift + P       Toggle power profile' \
          'Super + Q               Close focused app' \
          'Super + Shift + Q       Log out of Hyprland' \
          'Alt + Tab               Native Hyprland window cycle' \
          'Alt + Shift + Tab       Native Hyprland reverse window cycle' \
          'Super + Left            Focus tiled window left' \
          'Super + Right           Focus tiled window right' \
          'Super + Up              Focus tiled window up' \
          'Super + Down            Focus tiled window down' \
          'Super + Shift + Left    Move tiled window left' \
          'Super + Shift + Right   Move tiled window right' \
          'Super + Shift + Up      Move tiled window up' \
          'Super + Shift + Down    Move tiled window down' \
          'Super + Ctrl + Left     Shrink tiled window width' \
          'Super + Ctrl + Right    Grow tiled window width' \
          'Super + Ctrl + Up       Shrink tiled window height' \
          'Super + Ctrl + Down     Grow tiled window height' \
          'Super + T               Toggle next split direction' \
          'Super + H/J/K/L         Focus left/down/up/right' \
          'Super + Shift + H/J/K/L Move window left/down/up/right' \
          'Super + 1-0             Switch workspace' \
          'Super + Shift + 1-0     Move window to workspace' \
          'Super + Print           Copy area screenshot to clipboard' \
          'Super + Shift + S       Screenshot area and edit' \
          'Super + Alt + S         Save area screenshot' \
          'Print                   Screenshot area and edit' \
          'XF86 Audio/Brightness   Media volume and brightness keys' \
          'Super + Mouse Left      Drag window' \
          'Super + Mouse Right     Resize window' \
          'Copy shortcut list      Copy this list to clipboard'
      }

      fuzzel_args=(--dmenu --prompt 'Shortcut > ' --width 72 --lines 30)
      if [[ -f "${themeStateDir}/fuzzel.ini" ]]; then
        fuzzel_args=(--config "${themeStateDir}/fuzzel.ini" "''${fuzzel_args[@]}")
      fi

      selection="$(shortcut_list | fuzzel "''${fuzzel_args[@]}")"

      case "$selection" in
        "Super + Return"*) hyprctl dispatch exec "${terminalCommand}" ;;
        "Super + Space"*) hyprctl dispatch exec hypr-fuzzel ;;
        "Super + /"* | "Super + F1"*) hyprctl dispatch exec hypr-shortcuts ;;
        "Super + B"*) hyprctl dispatch exec "${browserCommand}" ;;
        "Super + W"*) hyprctl dispatch exec hypr-wallpaper-picker ;;
        "Super + Shift + W"*) hyprctl dispatch exec "hypr-wallpaper-picker --random" ;;
        "Super + E"*) hyprctl dispatch exec dolphin ;;
        "Super + F"*) hyprctl dispatch fullscreen ;;
        "Super + Shift + Space"*) hyprctl dispatch togglefloating ;;
        "Super + R"*) hyprctl reload ;;
        "Super + Ctrl + Left"*) hyprctl dispatch resizeactive -80 0 ;;
        "Super + Ctrl + Right"*) hyprctl dispatch resizeactive 80 0 ;;
        "Super + Ctrl + Up"*) hyprctl dispatch resizeactive 0 -80 ;;
        "Super + Ctrl + Down"*) hyprctl dispatch resizeactive 0 80 ;;
        "Super + Ctrl + L"*) hyprctl dispatch exec hypr-lock ;;
        "Super + N"*) hyprctl dispatch exec "swaync-client -t -sw" ;;
        "Super + V"*) hyprctl dispatch exec "sh -lc 'cliphist list | hypr-fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy'" ;;
        "Super + Shift + V"*) hyprctl dispatch exec "cliphist wipe" ;;
        "Super + Ctrl + B"*) hyprctl dispatch exec hypr-shell-start ;;
        "Super + C"*) hyprctl dispatch exec "hyprpicker -a" ;;
        "Super + Shift + P"*) hyprctl dispatch exec power-profile-toggle ;;
        "Super + Q"*) hyprctl dispatch killactive ;;
        "Super + Shift + Q"*) hyprctl dispatch exit ;;
        "Alt + Tab"*) hyprctl --batch "dispatch cyclenext; dispatch bringactivetotop" ;;
        "Alt + Shift + Tab"*) hyprctl --batch "dispatch cyclenext prev; dispatch bringactivetotop" ;;
        "Super + T"*) hyprctl dispatch togglesplit ;;
        "Super + Print"*) hyprctl dispatch exec "sh -lc 'grim -g \"$(slurp)\" - | wl-copy'" ;;
        "Super + Shift + S"*) hyprctl dispatch exec "sh -lc 'mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" - | satty -f - --copy-command wl-copy -o ~/Pictures/Screenshots/%Y%m%d-%H%M%S.png'" ;;
        "Super + Alt + S"*) hyprctl dispatch exec "sh -lc 'mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png'" ;;
        "Print"*) hyprctl dispatch exec "sh -lc 'mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" - | satty -f - --copy-command wl-copy -o ~/Pictures/Screenshots/%Y%m%d-%H%M%S.png'" ;;
        "Copy shortcut list"*) shortcut_list | wl-copy ;;
        *) ;;
      esac
    '';
  };
in {
  config = lib.mkIf cfgEnabled {
    home.packages = [
      hypr-kwallet-start
      hypr-shell-start
      hypr-shortcuts
      hypr-status
    ];

    xdg.desktopEntries.hyprland-shortcuts = {
      name = "Hyprland Shortcuts";
      genericName = "Shortcut Picker";
      exec = "hypr-shortcuts";
      icon = "preferences-desktop-keyboard-shortcuts";
      comment = "Show and run the configured Hyprland keybindings";
      categories = ["Settings" "Utility"];
      terminal = false;
    };
  };
}
