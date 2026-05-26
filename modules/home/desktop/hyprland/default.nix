{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  cfgEnabled = osConfig.myConfig.desktop.hyprland.enable or false;
  wallpaper = "${../../../../assets/wallpaper/wallpaper-static.png}";
  jsonFormat = pkgs.formats.json {};

  hypr-snap = pkgs.writeShellApplication {
    name = "hypr-snap";
    runtimeInputs = [
      pkgs.hyprland
      pkgs.jq
      hypr-window-switch
    ];
    text = ''
      set -euo pipefail

      action="''${1:-}"
      if [[ -z "$action" ]]; then
        exit 2
      fi

      active="$(hyprctl -j activewindow)"
      address="$(jq -r '.address // ""' <<< "$active")"
      if [[ -z "$address" || "$address" == "0x0" ]]; then
        exit 0
      fi

      monitors="$(hyprctl -j monitors)"
      monitor_id="$(jq -r '.monitor // ""' <<< "$active")"
      monitor="$(jq -c --arg id "$monitor_id" 'map(select((.id | tostring) == $id))[0] // map(select(.focused))[0] // .[0]' <<< "$monitors")"

      mx="$(jq -r '.x | floor' <<< "$monitor")"
      my="$(jq -r '.y | floor' <<< "$monitor")"
      mw="$(jq -r '.width | floor' <<< "$monitor")"
      mh="$(jq -r '.height | floor' <<< "$monitor")"
      reserved_left="$(jq -r '.reserved[0] // 0 | floor' <<< "$monitor")"
      reserved_top="$(jq -r '.reserved[1] // 0 | floor' <<< "$monitor")"
      reserved_right="$(jq -r '.reserved[2] // 0 | floor' <<< "$monitor")"
      reserved_bottom="$(jq -r '.reserved[3] // 0 | floor' <<< "$monitor")"
      mx=$((mx + reserved_left))
      my=$((my + reserved_top))
      mw=$((mw - reserved_left - reserved_right))
      mh=$((mh - reserved_top - reserved_bottom))
      wx="$(jq -r '.at[0] | floor' <<< "$active")"
      wy="$(jq -r '.at[1] | floor' <<< "$active")"
      ww="$(jq -r '.size[0] | floor' <<< "$active")"
      wh="$(jq -r '.size[1] | floor' <<< "$active")"
      floating="$(jq -r '.floating // false' <<< "$active")"
      fullscreen="$(jq -r '.fullscreen // 0' <<< "$active")"

      half_w=$((mw / 2))
      half_h=$((mh / 2))
      center_w=$((mw * 3 / 5))
      center_h=$((mh * 3 / 5))
      center_x=$((mx + (mw - center_w) / 2))
      center_y=$((my + (mh - center_h) / 2))

      approx() {
        local a="$1"
        local b="$2"
        local tol="''${3:-32}"
        (( a >= b - tol && a <= b + tol ))
      }

      is_left_half() {
        approx "$wx" "$mx" && approx "$wy" "$my" && approx "$ww" "$half_w" && approx "$wh" "$mh"
      }

      is_right_half() {
        approx "$wx" "$((mx + half_w))" && approx "$wy" "$my" && approx "$ww" "$half_w" && approx "$wh" "$mh"
      }

      is_top_half() {
        approx "$wx" "$mx" && approx "$wy" "$my" && approx "$ww" "$mw" && approx "$wh" "$half_h"
      }

      is_bottom_half() {
        approx "$wx" "$mx" && approx "$wy" "$((my + half_h))" && approx "$ww" "$mw" && approx "$wh" "$half_h"
      }

      is_top_left() {
        approx "$wx" "$mx" && approx "$wy" "$my" && approx "$ww" "$half_w" && approx "$wh" "$half_h"
      }

      is_top_right() {
        approx "$wx" "$((mx + half_w))" && approx "$wy" "$my" && approx "$ww" "$half_w" && approx "$wh" "$half_h"
      }

      is_bottom_left() {
        approx "$wx" "$mx" && approx "$wy" "$((my + half_h))" && approx "$ww" "$half_w" && approx "$wh" "$half_h"
      }

      is_bottom_right() {
        approx "$wx" "$((mx + half_w))" && approx "$wy" "$((my + half_h))" && approx "$ww" "$half_w" && approx "$wh" "$half_h"
      }

      ensure_floating() {
        if [[ "$fullscreen" != "0" ]]; then
          hyprctl dispatch fullscreen 1 >/dev/null 2>&1 || true
        fi
        if [[ "$floating" != "true" ]]; then
          hyprctl dispatch togglefloating active >/dev/null
          floating=true
        fi
      }

      place() {
        local x="$1"
        local y="$2"
        local w="$3"
        local h="$4"
        ensure_floating
        hyprctl --batch "dispatch resizeactive exact $w $h; dispatch moveactive exact $x $y" >/dev/null
      }

      minimize() {
        if [[ "$fullscreen" != "0" ]]; then
          hyprctl dispatch fullscreen 1 >/dev/null 2>&1 || true
        fi
        hypr-window-switch remember "$address"
        hyprctl dispatch movetoworkspacesilent special:minimized >/dev/null
      }

      maximize() {
        if [[ "$floating" == "true" ]]; then
          hyprctl dispatch togglefloating active >/dev/null
        fi
        if [[ "$fullscreen" == "0" ]]; then
          hyprctl dispatch fullscreen 1 >/dev/null
        fi
      }

      restore_center() {
        place "$center_x" "$center_y" "$center_w" "$center_h"
      }

      case "$action" in
        left)
          place "$mx" "$my" "$half_w" "$mh"
          ;;
        right)
          place "$((mx + half_w))" "$my" "$half_w" "$mh"
          ;;
        top)
          if is_left_half || is_bottom_left; then
            place "$mx" "$my" "$half_w" "$half_h"
          elif is_right_half || is_bottom_right; then
            place "$((mx + half_w))" "$my" "$half_w" "$half_h"
          elif is_top_left || is_top_right || is_top_half; then
            maximize
          else
            place "$mx" "$my" "$mw" "$half_h"
          fi
          ;;
        bottom)
          if is_left_half || is_top_left; then
            place "$mx" "$((my + half_h))" "$half_w" "$half_h"
          elif is_right_half || is_top_right; then
            place "$((mx + half_w))" "$((my + half_h))" "$half_w" "$half_h"
          elif is_bottom_left || is_bottom_right || is_bottom_half; then
            minimize
          else
            place "$mx" "$((my + half_h))" "$mw" "$half_h"
          fi
          ;;
        up)
          if is_bottom_left || is_left_half; then
            place "$mx" "$my" "$half_w" "$half_h"
          elif is_bottom_right || is_right_half; then
            place "$((mx + half_w))" "$my" "$half_w" "$half_h"
          elif [[ "$fullscreen" != "0" ]]; then
            restore_center
          else
            maximize
          fi
          ;;
        down)
          if is_top_left || is_left_half; then
            place "$mx" "$((my + half_h))" "$half_w" "$half_h"
          elif is_top_right || is_right_half; then
            place "$((mx + half_w))" "$((my + half_h))" "$half_w" "$half_h"
          elif is_bottom_left || is_bottom_right || is_bottom_half; then
            minimize
          elif [[ "$fullscreen" != "0" ]]; then
            restore_center
          else
            minimize
          fi
          ;;
        *)
          exit 2
          ;;
      esac
    '';
  };

  hypr-shell-fallback = pkgs.writeShellApplication {
    name = "hypr-shell-fallback";
    runtimeInputs = [
      pkgs.procps
      pkgs.quickshell
      pkgs.waybar
    ];
    text = ''
      pkill quickshell 2>/dev/null || true
      pkill waybar 2>/dev/null || true
      waybar >/tmp/waybar-hyprland.log 2>&1 &
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

  hypr-window-switch = pkgs.writeShellApplication {
    name = "hypr-window-switch";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.hyprland
      pkgs.jq
    ];
    text = ''
      set -euo pipefail

      runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
      state_file="$runtime_dir/hypr-minimized-order"
      action="''${1:-next}"

      ensure_state_file() {
        mkdir -p "$(dirname "$state_file")"
        touch "$state_file"
      }

      remove_from_state() {
        local address="$1"
        ensure_state_file
        local tmp
        tmp="$(mktemp "$runtime_dir/hypr-minimized-order.XXXXXX")"
        grep -vxF "$address" "$state_file" > "$tmp" || true
        mv "$tmp" "$state_file"
      }

      remember() {
        local address="''${1:-}"
        if [[ -z "$address" || "$address" == "0x0" ]]; then
          exit 0
        fi
        remove_from_state "$address"
        printf '%s\n' "$address" >> "$state_file"
      }

      fallback_cycle() {
        case "$action" in
          prev)
            hyprctl dispatch cyclenext prev >/dev/null
            ;;
          *)
            hyprctl dispatch cyclenext >/dev/null
            ;;
        esac
      }

      current_workspace_target() {
        local workspace
        workspace="$(hyprctl -j activeworkspace | jq -r '.id // empty')"
        if [[ "$workspace" =~ ^[0-9]+$ ]]; then
          printf '%s\n' "$workspace"
        else
          workspace="$(hyprctl -j activeworkspace | jq -r '.name // empty')"
          printf 'name:%s\n' "$workspace"
        fi
      }

      restore_minimized() {
        local clients
        local candidate=""
        clients="$(hyprctl -j clients)"

        ensure_state_file
        while IFS= read -r address; do
          if jq -e --arg address "$address" '.[] | select(.address == $address and .workspace.name == "special:minimized")' <<< "$clients" >/dev/null; then
            candidate="$address"
            break
          fi
        done < <(tac "$state_file")

        if [[ -z "$candidate" ]]; then
          candidate="$(jq -r '[.[] | select(.workspace.name == "special:minimized")][-1].address // ""' <<< "$clients")"
        fi

        if [[ -z "$candidate" ]]; then
          fallback_cycle
          exit 0
        fi

        remove_from_state "$candidate"

        local target
        target="$(current_workspace_target)"
        hyprctl --batch "dispatch movetoworkspacesilent $target,address:$candidate; dispatch focuswindow address:$candidate" >/dev/null
      }

      case "$action" in
        remember)
          remember "''${2:-}"
          ;;
        next | prev | restore)
          restore_minimized
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
      pkgs.hyprland
      pkgs.wl-clipboard
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
          'Super + Ctrl + L        Lock screen' \
          'Super + N               Notifications' \
          'Super + V               Clipboard history' \
          'Super + Shift + V       Clear clipboard history' \
          'Super + Q               Close focused app' \
          'Super + Shift + Q       Log out of Hyprland' \
          'Alt + Tab               Restore minimized or focus next' \
          'Alt + Shift + Tab       Restore minimized or focus previous' \
          'Super + Left            Snap left' \
          'Super + Right           Snap right' \
          'Super + Up              Maximize or move snap upward' \
          'Super + Down            Restore, move snap downward, or minimize' \
          'Super + Alt + Up        Snap top half' \
          'Super + Alt + Down      Snap bottom half' \
          'Super + Shift + Down    Restore minimized window' \
          'Super + H/J/K/L         Focus left/down/up/right' \
          'Super + Shift + H/J/K/L Move window left/down/up/right' \
          'Super + 1-0             Switch workspace' \
          'Super + Shift + 1-0     Move window to workspace' \
          'Super + Print           Copy area screenshot' \
          'Print                   Screenshot area and edit' \
          'Super + Mouse Left      Drag window' \
          'Super + Mouse Right     Resize window' \
          'Copy shortcut list      Copy this list to clipboard'
      }

      selection="$(shortcut_list | fuzzel --dmenu --prompt 'Shortcut > ' --width 68 --lines 22)"

      case "$selection" in
        "Super + Return"*) hyprctl dispatch exec warp-terminal ;;
        "Super + Space"*) hyprctl dispatch exec fuzzel ;;
        "Super + /"* | "Super + F1"*) hyprctl dispatch exec hypr-shortcuts ;;
        "Super + B"*) hyprctl dispatch exec "google-chrome-stable || google-chrome" ;;
        "Super + Ctrl + L"*) hyprctl dispatch exec hyprlock ;;
        "Super + N"*) hyprctl dispatch exec "swaync-client -t -sw" ;;
        "Super + V"*) hyprctl dispatch exec "sh -lc 'cliphist list | fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy'" ;;
        "Super + Shift + V"*) hyprctl dispatch exec "cliphist wipe" ;;
        "Super + Q"*) hyprctl dispatch killactive ;;
        "Super + Shift + Q"*) hyprctl dispatch exit ;;
        "Alt + Tab"*) hyprctl dispatch exec "hypr-window-switch next" ;;
        "Alt + Shift + Tab"*) hyprctl dispatch exec "hypr-window-switch prev" ;;
        "Super + Left"*) hyprctl dispatch exec "hypr-snap left" ;;
        "Super + Right"*) hyprctl dispatch exec "hypr-snap right" ;;
        "Super + Up"*) hyprctl dispatch exec "hypr-snap up" ;;
        "Super + Down"*) hyprctl dispatch exec "hypr-snap down" ;;
        "Super + Alt + Up"*) hyprctl dispatch exec "hypr-snap top" ;;
        "Super + Alt + Down"*) hyprctl dispatch exec "hypr-snap bottom" ;;
        "Super + Shift + Down"*) hyprctl dispatch exec "hypr-window-switch restore" ;;
        "Super + H/J/K/L"*) ;;
        "Super + Shift + H/J/K/L"*) ;;
        "Super + 1-0"*) ;;
        "Super + Shift + 1-0"*) ;;
        "Super + Print"*) hyprctl dispatch exec "sh -lc 'grim -g \"$(slurp)\" - | wl-copy'" ;;
        "Print"*) hyprctl dispatch exec "sh -lc 'mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" - | satty -f - --copy-command wl-copy -o ~/Pictures/Screenshots/%Y%m%d-%H%M%S.png'" ;;
        "Copy shortcut list"*) shortcut_list | wl-copy ;;
        *) ;;
      esac
    '';
  };
in {
  config = lib.mkIf cfgEnabled {
    home.packages = with pkgs; [
      cliphist
      fuzzel
      grim
      hypridle
      hyprlock
      hyprpaper
      hyprpicker
      hyprpolkitagent
      hyprsunset
      jq
      quickshell
      satty
      slurp
      swaynotificationcenter
      waybar
      wl-clipboard
      brightnessctl
      hypr-snap
      hypr-shell-fallback
      hypr-shortcuts
      hypr-status
      hypr-window-switch
    ];

    xdg.configFile."hypr/hyprland.conf" = {
      force = true;
      text = ''
        # Managed by Home Manager.
        autogenerated = 0

        monitor = HDMI-A-1,3840x2160@119.88,0x0,1

        $mod = SUPER
        $terminal = warp-terminal
        $launcher = fuzzel

        exec-once = hyprpaper
        exec-once = hypridle
        exec-once = hyprpolkitagent
        exec-once = swaync
        exec-once = quickshell --no-duplicate --config hypr-shell
        exec-once = wl-paste --type text --watch cliphist store
        exec-once = wl-paste --type image --watch cliphist store

        input {
          kb_layout = us
          follow_mouse = 1
          sensitivity = 0
          touchpad {
            natural_scroll = true
          }
        }

        general {
          gaps_in = 5
          gaps_out = 10
          border_size = 2
          col.active_border = rgba(9ccfd8ee) rgba(c4a7e7ee) 45deg
          col.inactive_border = rgba(403d5266)
          layout = dwindle
          allow_tearing = false
        }

        decoration {
          rounding = 10
          active_opacity = 0.96
          inactive_opacity = 0.90
          shadow {
            enabled = true
            range = 18
            render_power = 3
            color = rgba(00000066)
          }
          blur {
            enabled = true
            size = 7
            passes = 3
            new_optimizations = true
            ignore_opacity = true
          }
        }

        animations {
          enabled = true
          bezier = easeOut, 0.16, 1, 0.3, 1
          animation = windows, 1, 4, easeOut, popin 85%
          animation = windowsOut, 1, 3, easeOut, popin 85%
          animation = border, 1, 6, easeOut
          animation = fade, 1, 4, easeOut
          animation = workspaces, 1, 4, easeOut, slide
        }

        dwindle {
          pseudotile = true
          preserve_split = true
          smart_split = true
        }

        misc {
          disable_hyprland_logo = true
          disable_splash_rendering = true
          focus_on_activate = true
          vfr = true
        }

        bind = $mod, RETURN, exec, $terminal
        bind = $mod, SPACE, exec, $launcher
        bind = $mod, slash, exec, hypr-shortcuts
        bind = $mod, F1, exec, hypr-shortcuts
        bind = $mod, B, exec, google-chrome-stable || google-chrome
        bind = $mod, Q, killactive
        bind = $mod SHIFT, Q, exit
        bind = ALT, TAB, exec, hypr-window-switch next
        bind = ALT SHIFT, TAB, exec, hypr-window-switch prev
        bind = $mod CTRL, L, exec, hyprlock
        bind = $mod, V, exec, sh -lc 'cliphist list | fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy'
        bind = $mod SHIFT, V, exec, cliphist wipe
        bind = $mod, N, exec, swaync-client -t -sw
        bind = $mod SHIFT, B, exec, hypr-shell-fallback

        bind = $mod, LEFT, exec, hypr-snap left
        bind = $mod, RIGHT, exec, hypr-snap right
        bind = $mod, UP, exec, hypr-snap up
        bind = $mod, DOWN, exec, hypr-snap down
        bind = $mod ALT, UP, exec, hypr-snap top
        bind = $mod ALT, DOWN, exec, hypr-snap bottom
        bind = $mod SHIFT, DOWN, exec, hypr-window-switch restore

        bind = $mod, H, movefocus, l
        bind = $mod, J, movefocus, d
        bind = $mod, K, movefocus, u
        bind = $mod, L, movefocus, r
        bind = $mod SHIFT, H, movewindow, l
        bind = $mod SHIFT, J, movewindow, d
        bind = $mod SHIFT, K, movewindow, u
        bind = $mod SHIFT, L, movewindow, r

        bind = $mod, 1, workspace, 1
        bind = $mod, 2, workspace, 2
        bind = $mod, 3, workspace, 3
        bind = $mod, 4, workspace, 4
        bind = $mod, 5, workspace, 5
        bind = $mod, 6, workspace, 6
        bind = $mod, 7, workspace, 7
        bind = $mod, 8, workspace, 8
        bind = $mod, 9, workspace, 9
        bind = $mod, 0, workspace, 10
        bind = $mod SHIFT, 1, movetoworkspacesilent, 1
        bind = $mod SHIFT, 2, movetoworkspacesilent, 2
        bind = $mod SHIFT, 3, movetoworkspacesilent, 3
        bind = $mod SHIFT, 4, movetoworkspacesilent, 4
        bind = $mod SHIFT, 5, movetoworkspacesilent, 5
        bind = $mod SHIFT, 6, movetoworkspacesilent, 6
        bind = $mod SHIFT, 7, movetoworkspacesilent, 7
        bind = $mod SHIFT, 8, movetoworkspacesilent, 8
        bind = $mod SHIFT, 9, movetoworkspacesilent, 9
        bind = $mod SHIFT, 0, movetoworkspacesilent, 10

        bind = , PRINT, exec, sh -lc 'mkdir -p ~/Pictures/Screenshots && grim -g "$(slurp)" - | satty -f - --copy-command wl-copy -o ~/Pictures/Screenshots/%Y%m%d-%H%M%S.png'
        bind = $mod, PRINT, exec, sh -lc 'grim -g "$(slurp)" - | wl-copy'

        bindel = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+
        bindel = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
        bindel = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        bindel = , XF86MonBrightnessUp, exec, brightnessctl set 5%+
        bindel = , XF86MonBrightnessDown, exec, brightnessctl set 5%-

        bindm = $mod, mouse:272, movewindow
        bindm = $mod, mouse:273, resizewindow

        windowrule = float on, match:class ^(fuzzel)$
        windowrule = float on, match:class ^(org.kde.polkit-kde-authentication-agent-1)$
        windowrule = float on, match:class ^(pavucontrol)$
        windowrule = float on, match:title ^(Picture-in-Picture)$
        windowrule = pin on, match:title ^(Picture-in-Picture)$
      '';
    };

    xdg.configFile."hypr/hyprpaper.conf" = {
      force = true;
      text = ''
        splash = false
        wallpaper {
          monitor = HDMI-A-1
          path = ${wallpaper}
          fit_mode = cover
        }
      '';
    };

    xdg.configFile."hypr/hypridle.conf" = {
      force = true;
      text = ''
        general {
          lock_cmd = pidof hyprlock || hyprlock
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch dpms on
        }

        listener {
          timeout = 900
          on-timeout = hyprlock
        }

        listener {
          timeout = 1200
          on-timeout = hyprctl dispatch dpms off
          on-resume = hyprctl dispatch dpms on
        }
      '';
    };

    xdg.configFile."hypr/hyprlock.conf" = {
      force = true;
      text = ''
        background {
          monitor =
          path = ${wallpaper}
          blur_passes = 3
          blur_size = 7
        }

        input-field {
          monitor =
          size = 360, 58
          position = 0, -120
          halign = center
          valign = center
          outline_thickness = 1
          dots_size = 0.25
          dots_spacing = 0.25
          outer_color = rgba(9ccfd899)
          inner_color = rgba(191724cc)
          font_color = rgba(e0def4ff)
          fade_on_empty = false
          placeholder_text = Password
        }

        label {
          monitor =
          text = cmd[update:1000] date +"%H:%M"
          color = rgba(e0def4ff)
          font_size = 72
          position = 0, 80
          halign = center
          valign = center
        }

        label {
          monitor =
          text = pc-02
          color = rgba(ebbcbaee)
          font_size = 18
          position = 0, 20
          halign = center
          valign = center
        }
      '';
    };

    xdg.configFile."quickshell/hypr-shell/shell.qml" = {
      force = true;
      text = ''
        import Quickshell
        import Quickshell.Io
        import Quickshell.Wayland
        import Quickshell.Hyprland
        import QtQuick
        import QtQuick.Layouts

        ShellRoot {
          PanelWindow {
            id: root
            anchors {
              top: true
              left: true
              right: true
            }
            implicitHeight: 38
            exclusiveZone: implicitHeight
            exclusionMode: ExclusionMode.Normal
            color: "transparent"

            property color bg: "#dc17191d"
            property color bgSoft: "#24272e"
            property color bgHover: "#30343d"
            property color fg: "#f2f0e8"
            property color muted: "#a7adb8"
            property color accent: "#7dd3fc"
            property color warning: "#f4c95d"
            property string timeText: Qt.formatDateTime(new Date(), "ddd HH:mm")
            property string volumeText: "Vol --"
            property string networkText: "Net --"
            property string bluetoothText: "BT --"

            function exec(command) {
              Hyprland.dispatch("exec " + command)
            }

            Timer {
              interval: 1000
              running: true
              repeat: true
              onTriggered: root.timeText = Qt.formatDateTime(new Date(), "ddd HH:mm")
            }

            Process {
              id: volumeProc
              command: ["hypr-status", "volume"]
              running: true
              stdout: StdioCollector {
                onStreamFinished: root.volumeText = this.text.trim()
              }
            }

            Process {
              id: networkProc
              command: ["hypr-status", "network"]
              running: true
              stdout: StdioCollector {
                onStreamFinished: root.networkText = this.text.trim()
              }
            }

            Process {
              id: bluetoothProc
              command: ["hypr-status", "bluetooth"]
              running: true
              stdout: StdioCollector {
                onStreamFinished: root.bluetoothText = this.text.trim()
              }
            }

            Timer {
              interval: 3000
              running: true
              repeat: true
              onTriggered: {
                volumeProc.running = true
                networkProc.running = true
                bluetoothProc.running = true
              }
            }

            component BarButton: Rectangle {
              id: button
              property string label: ""
              property string hint: ""
              property bool active: false
              property bool subtle: false
              signal leftClicked()
              signal rightClicked()

              Layout.preferredWidth: Math.max(44, labelText.implicitWidth + (hint === "" ? 22 : hintText.implicitWidth + 34))
              Layout.preferredHeight: 26
              radius: 6
              clip: true
              color: active ? root.accent : (mouse.containsMouse ? root.bgHover : (subtle ? "transparent" : root.bgSoft))
              border.width: subtle ? 0 : 1
              border.color: active ? root.accent : "#34404a"

              RowLayout {
                anchors {
                  fill: parent
                  leftMargin: 10
                  rightMargin: 10
                }
                spacing: 6
                Text {
                  id: labelText
                  Layout.fillWidth: true
                  text: button.label
                  elide: Text.ElideRight
                  maximumLineCount: 1
                  color: button.active ? "#111318" : root.fg
                  font.pixelSize: 12
                  font.bold: button.active
                }
                Text {
                  id: hintText
                  visible: button.hint !== ""
                  Layout.fillWidth: false
                  text: button.hint
                  color: button.active ? "#1f2933" : root.muted
                  font.pixelSize: 11
                }
              }

              MouseArea {
                id: mouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                onClicked: event => event.button === Qt.RightButton ? button.rightClicked() : button.leftClicked()
              }
            }

            Rectangle {
              anchors.fill: parent
              radius: 0
              color: root.bg
              border.color: "#25313a"
              border.width: 0

              RowLayout {
                anchors {
                  fill: parent
                  leftMargin: 10
                  rightMargin: 10
                }
                spacing: 8

                BarButton {
                  label: "Apps"
                  hint: "Space"
                  onLeftClicked: root.exec("fuzzel")
                  onRightClicked: root.exec("hypr-shortcuts")
                }

                RowLayout {
                  Layout.preferredHeight: 26
                  spacing: 4
                  Repeater {
                    model: 10
                    delegate: BarButton {
                      required property int index
                      property int wsId: index + 1
                      property var ws: Hyprland.workspaces.values.find(w => w.id === wsId)
                      Layout.preferredWidth: 26
                      label: String(wsId)
                      active: Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === wsId
                      subtle: !active && !ws
                      onLeftClicked: Hyprland.dispatch("workspace " + wsId)
                      onRightClicked: Hyprland.dispatch("movetoworkspacesilent " + wsId)
                    }
                  }
                }

                BarButton {
                  Layout.fillWidth: true
                  label: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
                  hint: "Alt+Tab"
                  subtle: true
                  onLeftClicked: root.exec("hypr-window-switch next")
                  onRightClicked: Hyprland.dispatch("killactive")
                }

                BarButton {
                  label: root.volumeText
                  hint: "Audio"
                  active: root.volumeText === "Muted"
                  onLeftClicked: root.exec("pavucontrol")
                  onRightClicked: {
                    root.exec("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
                    volumeProc.running = true
                  }
                }

                BarButton {
                  label: root.networkText
                  hint: "Net"
                  onLeftClicked: root.exec("systemsettings kcm_networkmanagement")
                  onRightClicked: root.exec("ktailctl")
                }

                BarButton {
                  label: root.bluetoothText
                  hint: "BT"
                  active: root.bluetoothText === "BT off"
                  onLeftClicked: root.exec("systemsettings kcm_bluetooth")
                  onRightClicked: root.exec("bluedevil-wizard")
                }

                BarButton {
                  label: root.timeText
                  hint: "Notifs"
                  onLeftClicked: root.exec("swaync-client -t -sw")
                  onRightClicked: root.exec("systemsettings kcm_clock")
                }

                BarButton {
                  label: "Lock"
                  hint: "L"
                  onLeftClicked: root.exec("hyprlock")
                  onRightClicked: Hyprland.dispatch("exit")
                }
              }

              Rectangle {
                anchors {
                  left: parent.left
                  right: parent.right
                  bottom: parent.bottom
                }
                height: 1
                color: "#2f3b45"
              }
            }
          }
        }
      '';
    };

    xdg.configFile."fuzzel/fuzzel.ini" = {
      force = true;
      text = ''
        [main]
        font=JetBrainsMono Nerd Font:size=13
        width=54
        lines=14
        horizontal-pad=18
        vertical-pad=14
        inner-pad=10
        terminal=warp-terminal
        prompt="> "
        layer=overlay

        [colors]
        background=191724dd
        text=e0def4ff
        prompt=9ccfd8ff
        input=e0def4ff
        match=ebbcbaff
        selection=403d52ee
        selection-text=e0def4ff
        border=9ccfd8aa

        [border]
        width=1
        radius=12
      '';
    };

    xdg.configFile."swaync/config.json" = {
      force = true;
      source = jsonFormat.generate "swaync-config.json" {
        positionX = "right";
        positionY = "top";
        layer = "overlay";
        control-center-layer = "top";
        cssPriority = "user";
        control-center-margin-top = 58;
        control-center-margin-bottom = 10;
        control-center-margin-right = 10;
        control-center-margin-left = 10;
        notification-window-width = 420;
        timeout = 8;
        timeout-low = 4;
        timeout-critical = 0;
        widgets = [
          "title"
          "dnd"
          "notifications"
          "mpris"
        ];
        widget-config.title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear";
        };
      };
    };

    xdg.configFile."swaync/style.css" = {
      force = true;
      text = ''
        * {
          font-family: "JetBrainsMono Nerd Font", sans-serif;
          font-size: 13px;
        }

        .control-center,
        .notification {
          background: rgba(25, 23, 36, 0.88);
          color: #e0def4;
          border: 1px solid rgba(156, 207, 216, 0.35);
          border-radius: 14px;
        }

        .notification-content {
          padding: 10px;
        }

        .summary {
          color: #e0def4;
          font-weight: 700;
        }

        .body,
        .time {
          color: #908caa;
        }

        button {
          background: rgba(64, 61, 82, 0.85);
          color: #e0def4;
          border: 1px solid rgba(156, 207, 216, 0.25);
          border-radius: 10px;
          padding: 6px 10px;
        }

        button:hover {
          background: rgba(156, 207, 216, 0.22);
        }
      '';
    };

    xdg.configFile."waybar/config" = {
      force = true;
      source = jsonFormat.generate "waybar-config.json" [
        {
          layer = "top";
          position = "top";
          height = 34;
          margin-top = 8;
          margin-left = 8;
          margin-right = 8;
          modules-left = ["hyprland/workspaces"];
          modules-center = ["hyprland/window"];
          modules-right = [
            "pulseaudio"
            "network"
            "clock"
          ];
          "hyprland/workspaces" = {
            format = "{id}";
            persistent-workspaces."*" = 10;
          };
          "hyprland/window".max-length = 90;
          pulseaudio = {
            format = "Audio {volume}%";
            format-muted = "Muted";
          };
          network = {
            format-wifi = "WiFi {essid}";
            format-ethernet = "Net {ipaddr}";
            format-disconnected = "Offline";
          };
          clock.format = "{:%a %H:%M}";
        }
      ];
    };

    xdg.configFile."waybar/style.css" = {
      force = true;
      text = ''
        * {
          font-family: "JetBrainsMono Nerd Font", sans-serif;
          font-size: 13px;
          border: none;
          min-height: 0;
        }

        window#waybar {
          background: rgba(25, 23, 36, 0.86);
          color: #e0def4;
          border: 1px solid rgba(156, 207, 216, 0.35);
          border-radius: 14px;
        }

        #workspaces button {
          color: #908caa;
          padding: 0 10px;
          border-radius: 10px;
        }

        #workspaces button.active {
          color: #191724;
          background: #9ccfd8;
        }

        #window,
        #pulseaudio,
        #network,
        #clock {
          padding: 0 12px;
        }
      '';
    };
  };
}
