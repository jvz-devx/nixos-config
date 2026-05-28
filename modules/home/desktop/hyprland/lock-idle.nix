{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  hyprlandCfg = osConfig.myConfig.desktop.hyprland or {};
  cfgEnabled = hyprlandCfg.enable or false;
  homeDir = config.home.homeDirectory;
  themeStateDir = "${homeDir}/.cache/hypr-theme";
  wallpaper = "${../../../../assets/wallpaper/wallpaper-static.png}";

  hypr-lock = pkgs.writeShellApplication {
    name = "hypr-lock";
    runtimeInputs = [
      pkgs.hyprlock
    ];
    text = ''
      set -euo pipefail

      config="${themeStateDir}/hyprlock.conf"
      if [[ ! -f "$config" ]]; then
        config="${homeDir}/.config/hypr/hyprlock.conf"
      fi

      exec hyprlock -c "$config" "$@"
    '';
  };
in {
  config = lib.mkIf cfgEnabled {
    home.packages = [
      hypr-lock
    ];

    xdg.configFile."hypr/hypridle.conf" = {
      force = true;
      text = ''
        general {
          lock_cmd = pidof hyprlock || hypr-lock
          before_sleep_cmd = loginctl lock-session
          after_sleep_cmd = hyprctl dispatch dpms on
        }

        listener {
          timeout = 900
          on-timeout = hypr-lock
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
          text = ${osConfig.networking.hostName or "nixos"}
          color = rgba(ebbcbaee)
          font_size = 18
          position = 0, 20
          halign = center
          valign = center
        }
      '';
    };
  };
}
