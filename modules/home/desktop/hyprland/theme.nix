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
  hyprlandPackage = osConfig.programs.hyprland.package or pkgs.hyprland;
  homeDir = config.home.homeDirectory;
  themeStateDir = "${homeDir}/.cache/hypr-theme";
  wallpaper = "${../../../../assets/wallpaper/wallpaper-static.png}";

  hypr-theme-apply = pkgs.writeShellApplication {
    name = "hypr-theme-apply";
    runtimeInputs = [
      pkgs.awww
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.jq
      pkgs.kitty
      pkgs.procps
      pkgs.swaynotificationcenter
      pkgs.wallust
      pkgs.waybar
      hyprlandPackage
    ];
    text = ''
      set -euo pipefail

      state_dir="${themeStateDir}"
      default_wallpaper="${wallpaper}"
      reload_ui=1
      init=0
      image=""

      while [[ $# -gt 0 ]]; do
        case "$1" in
          --init)
            init=1
            shift
            ;;
          --no-reload)
            reload_ui=0
            shift
            ;;
          *)
            image="$1"
            shift
            ;;
        esac
      done

      mkdir -p "$state_dir"

      if [[ "$init" == "1" && -z "$image" && -f "$state_dir/current-wallpaper.path" ]]; then
        image="$(<"$state_dir/current-wallpaper.path")"
      fi

      if [[ -z "$image" || ! -f "$image" ]]; then
        image="$default_wallpaper"
      fi

      ln -sfn "$image" "$state_dir/current-wallpaper"
      printf '%s\n' "$image" > "$state_dir/current-wallpaper.path"

      mapfile -t colors < <(
        XDG_CACHE_HOME="$state_dir/wallust-cache" \
        XDG_CONFIG_HOME="$state_dir/wallust-config" \
          wallust run -q -s -T --print-scheme "$image" 2>/dev/null \
          | grep -E '^#[0-9A-Fa-f]{6}$' \
          | head -16
      )

      if (( ''${#colors[@]} < 16 )); then
        colors=(
          "#191724" "#eb6f92" "#9ccfd8" "#f6c177"
          "#31748f" "#c4a7e7" "#ebbcba" "#e0def4"
          "#6e6a86" "#eb6f92" "#9ccfd8" "#f6c177"
          "#31748f" "#c4a7e7" "#ebbcba" "#e0def4"
        )
      fi

      bg="''${colors[0]}"
      bg_soft="''${colors[1]}"
      bg_hover="''${colors[8]}"
      fg="''${colors[15]}"
      muted="''${colors[7]}"
      accent="''${colors[6]}"
      warning="''${colors[3]}"
      selection="''${colors[4]}"
      selection_text="''${colors[15]}"

      strip_hash() {
        printf '%s' "''${1#\#}"
      }

      bg_hex="$(strip_hash "$bg")"
      bg_hover_hex="$(strip_hash "$bg_hover")"
      fg_hex="$(strip_hash "$fg")"
      accent_hex="$(strip_hash "$accent")"
      warning_hex="$(strip_hash "$warning")"
      selection_hex="$(strip_hash "$selection")"
      selection_text_hex="$(strip_hash "$selection_text")"

      cat > "$state_dir/kitty-colors.conf" <<EOF
      foreground $fg
      background $bg
      selection_foreground $selection_text
      selection_background $selection
      cursor $accent
      cursor_text_color $bg
      url_color $accent
      active_border_color $accent
      inactive_border_color $bg_hover
      bell_border_color $warning
      active_tab_foreground $bg
      active_tab_background $accent
      inactive_tab_foreground $fg
      inactive_tab_background $bg_soft
      tab_bar_background $bg
      color0 ''${colors[0]}
      color1 ''${colors[1]}
      color2 ''${colors[2]}
      color3 ''${colors[3]}
      color4 ''${colors[4]}
      color5 ''${colors[5]}
      color6 ''${colors[6]}
      color7 ''${colors[7]}
      color8 ''${colors[8]}
      color9 ''${colors[9]}
      color10 ''${colors[10]}
      color11 ''${colors[11]}
      color12 ''${colors[12]}
      color13 ''${colors[13]}
      color14 ''${colors[14]}
      color15 ''${colors[15]}
      EOF

      cat > "$state_dir/fuzzel.ini" <<EOF
      [main]
      font=JetBrainsMono Nerd Font:size=13
      width=54
      lines=14
      horizontal-pad=18
      vertical-pad=14
      inner-pad=10
      terminal=${terminalCommand}
      prompt="> "
      layer=overlay

      [colors]
      background=''${bg_hex}ee
      text=''${fg_hex}ff
      prompt=''${accent_hex}ff
      input=''${fg_hex}ff
      match=''${warning_hex}ff
      selection=''${selection_hex}ee
      selection-text=''${selection_text_hex}ff
      border=''${accent_hex}aa

      [border]
      width=1
      radius=12
      EOF

      cat > "$state_dir/swaync.css" <<EOF
      * {
        font-family: "JetBrainsMono Nerd Font", sans-serif;
        font-size: 13px;
      }

      .control-center,
      .notification {
        background: $bg;
        color: $fg;
        border: 1px solid $accent;
        border-radius: 14px;
      }

      .notification-content {
        padding: 10px;
      }

      .summary {
        color: $fg;
        font-weight: 700;
      }

      .body,
      .time {
        color: $muted;
      }

      button {
        background: $bg_soft;
        color: $fg;
        border: 1px solid $accent;
        border-radius: 10px;
        padding: 6px 10px;
      }

      button:hover {
        background: $bg_hover;
      }
      EOF

      cat > "$state_dir/waybar.css" <<EOF
      @define-color bar-bg $bg;
      @define-color main-bg $bg_soft;
      @define-color main-fg $fg;
      @define-color wb-act-bg $accent;
      @define-color wb-act-fg $bg;
      @define-color wb-hvr-bg $bg_hover;
      @define-color wb-hvr-fg $fg;
      @define-color border-color $accent;
      @define-color muted $muted;
      @define-color warning $warning;
      EOF

      cat > "$state_dir/hyprlock.conf" <<EOF
      background {
        monitor =
        path = $image
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
        outer_color = rgba(''${accent_hex}cc)
        inner_color = rgba(''${bg_hex}dd)
        font_color = rgba(''${fg_hex}ff)
        fade_on_empty = false
        placeholder_text = Password
      }

      label {
        monitor =
        text = cmd[update:1000] date +"%H:%M"
        color = rgba(''${fg_hex}ff)
        font_size = 72
        position = 0, 80
        halign = center
        valign = center
      }

      label {
        monitor =
        text = ${osConfig.networking.hostName or "nixos"}
        color = rgba(''${accent_hex}ee)
        font_size = 18
        position = 0, 20
        halign = center
        valign = center
      }
      EOF

      if ! awww query >/dev/null 2>&1; then
        nohup awww-daemon --format xrgb --quiet >/tmp/awww-daemon.log 2>&1 &
        sleep 0.2
      fi

      transition_pos="$(hyprctl cursorpos 2>/dev/null | grep -E '^[0-9]' || echo "center")"
      awww img "$image" \
        --transition-bezier .43,1.19,1,.4 \
        --transition-type grow \
        --transition-duration 1 \
        --transition-fps 60 \
        --invert-y \
        --transition-pos "$transition_pos" >/tmp/awww-img.log 2>&1 || true

      hyprctl keyword general:col.active_border "rgba(''${accent_hex}ee) rgba(''${warning_hex}ee) 45deg" >/dev/null 2>&1 || true
      hyprctl keyword general:col.inactive_border "rgba(''${bg_hover_hex}66)" >/dev/null 2>&1 || true

      if (( reload_ui )); then
        kitty @ --to "unix:$state_dir/kitty.sock" set-colors --all --configured "$state_dir/kitty-colors.conf" >/dev/null 2>&1 || true
        if pgrep -x swaync >/dev/null 2>&1; then
          pkill -x swaync 2>/dev/null || true
          swaync -c "${homeDir}/.config/swaync/config.json" -s "$state_dir/swaync.css" >/tmp/swaync-hyprland.log 2>&1 &
        fi
        pkill -x waybar 2>/dev/null || true
        pkill -x .waybar-wrapped 2>/dev/null || true
        nohup waybar >/tmp/waybar-hyprland.log 2>&1 &
      fi
    '';
  };

  hypr-fuzzel = pkgs.writeShellApplication {
    name = "hypr-fuzzel";
    runtimeInputs = [
      pkgs.fuzzel
      hypr-theme-apply
    ];
    text = ''
      set -euo pipefail

      config="${themeStateDir}/fuzzel.ini"
      if [[ ! -f "$config" ]]; then
        hypr-theme-apply --init --no-reload
      fi

      exec fuzzel --config "$config" "$@"
    '';
  };

  hypr-swaync-start = pkgs.writeShellApplication {
    name = "hypr-swaync-start";
    runtimeInputs = [
      pkgs.procps
      pkgs.swaynotificationcenter
      hypr-theme-apply
    ];
    text = ''
      set -euo pipefail

      css="${themeStateDir}/swaync.css"
      if [[ ! -f "$css" ]]; then
        hypr-theme-apply --init --no-reload
      fi

      pkill -x swaync 2>/dev/null || true
      exec swaync -c "${homeDir}/.config/swaync/config.json" -s "$css"
    '';
  };

  hypr-wallpaper-picker = pkgs.writeShellApplication {
    name = "hypr-wallpaper-picker";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.file
      pkgs.findutils
      pkgs.gawk
      pkgs.gnugrep
      hypr-fuzzel
      hypr-theme-apply
    ];
    text = ''
      set -euo pipefail

      wallpaper_dirs=(
        "/etc/nixos/reference-material/wallpapers/native-4k-pixel-dream"
        "/etc/nixos/reference-material/wallpapers/native-4k-hyde-macos"
        "/etc/nixos/reference-material/wallpapers/native-4k-macos-like"
        "${homeDir}/Pictures/Wallpapers"
        "${homeDir}/Pictures/wallpapers"
      )

      is_native_4k() {
        LC_ALL=C file -b "$1" 2>/dev/null | grep -Eq '3840[[:space:]]*x[[:space:]]*2160'
      }

      collect_wallpapers() {
        for dir in "''${wallpaper_dirs[@]}"; do
          [[ -d "$dir" ]] || continue
          find "$dir" -type f \( \
            -iname '*.png' -o \
            -iname '*.jpg' -o \
            -iname '*.jpeg' -o \
            -iname '*.webp' \
          \) -print \
            | while IFS= read -r image; do
                is_native_4k "$image" && printf '%s\n' "$image"
              done
        done
      }

      if [[ "''${1:-}" == "--random" ]]; then
        mapfile -t wallpapers < <(collect_wallpapers)
        if (( ''${#wallpapers[@]} == 0 )); then
          exit 1
        fi
        hypr-theme-apply "''${wallpapers[RANDOM % ''${#wallpapers[@]}]}"
        exit 0
      fi

      selection="$(
        collect_wallpapers \
          | awk -F/ '{ print $NF "\t" $0 }' \
          | sort -f \
          | hypr-fuzzel --dmenu --prompt 'Wallpaper > ' --width 96 --lines 24 --with-nth 1 --accept-nth 2
      )"

      [[ -n "$selection" ]] || exit 0
      hypr-theme-apply "$selection"
    '';
  };
in {
  config = lib.mkIf cfgEnabled {
    home.packages = [
      pkgs.awww
      pkgs.fuzzel
      pkgs.wallust
      hypr-fuzzel
      hypr-swaync-start
      hypr-theme-apply
      hypr-wallpaper-picker
    ];

    home.activation.createHyprThemeKittyColors = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p ${themeStateDir}
      if [ ! -e ${themeStateDir}/kitty-colors.conf ]; then
        $DRY_RUN_CMD install -m 0644 /dev/stdin ${themeStateDir}/kitty-colors.conf <<'EOF'
      foreground #e0def4
      background #191724
      selection_foreground #e0def4
      selection_background #31748f
      cursor #ebbcba
      cursor_text_color #191724
      url_color #9ccfd8
      active_border_color #9ccfd8
      inactive_border_color #6e6a86
      bell_border_color #f6c177
      active_tab_foreground #191724
      active_tab_background #9ccfd8
      inactive_tab_foreground #e0def4
      inactive_tab_background #26233a
      tab_bar_background #191724
      color0 #191724
      color1 #eb6f92
      color2 #9ccfd8
      color3 #f6c177
      color4 #31748f
      color5 #c4a7e7
      color6 #ebbcba
      color7 #e0def4
      color8 #6e6a86
      color9 #eb6f92
      color10 #9ccfd8
      color11 #f6c177
      color12 #31748f
      color13 #c4a7e7
      color14 #ebbcba
      color15 #e0def4
      EOF
      fi
    '';

    xdg.configFile."kitty/kitty.conf" = {
      force = true;
      text = ''
        # Managed by Home Manager.
        include ${themeStateDir}/kitty-colors.conf

        font_family JetBrainsMono Nerd Font
        bold_font auto
        italic_font auto
        bold_italic_font auto
        font_size 12.5
        disable_ligatures never

        cursor_shape beam
        cursor_blink_interval 0.5
        cursor_trail 1
        enable_audio_bell no
        visual_bell_duration 0.0
        window_alert_on_bell no

        background_opacity 0.86
        dynamic_background_opacity yes
        window_padding_width 10
        single_window_margin_width 0
        placement_strategy center
        hide_window_decorations yes

        tab_bar_edge bottom
        tab_bar_style powerline
        tab_powerline_style slanted
        tab_title_template "{fmt.fg._9ccfd8}{index}{fmt.fg.default}: {title}"
        active_tab_font_style bold
        inactive_tab_font_style normal

        scrollback_lines 20000
        wheel_scroll_multiplier 3.0
        touch_scroll_multiplier 3.0
        copy_on_select clipboard
        strip_trailing_spaces smart
        open_url_with default
        url_style curly

        allow_remote_control yes
        listen_on unix:${themeStateDir}/kitty.sock
        shell_integration enabled
        confirm_os_window_close 0
        update_check_interval 0

        map ctrl+shift+enter new_window_with_cwd
        map ctrl+shift+t new_tab_with_cwd
        map ctrl+shift+w close_tab
        map ctrl+shift+h previous_tab
        map ctrl+shift+l next_tab
        map ctrl+shift+c copy_to_clipboard
        map ctrl+shift+v paste_from_clipboard
        map ctrl+shift+equal change_font_size all +1.0
        map ctrl+shift+minus change_font_size all -1.0
        map ctrl+shift+backspace change_font_size all 0
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
        terminal=${terminalCommand}
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
      source = (pkgs.formats.json {}).generate "swaync-config.json" {
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
  };
}
