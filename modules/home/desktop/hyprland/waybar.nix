{
  lib,
  osConfig,
  pkgs,
  config,
  ...
}: let
  hyprlandCfg = osConfig.myConfig.desktop.hyprland or {};
  cfgEnabled = hyprlandCfg.enable or false;
  themeStateDir = "${config.home.homeDirectory}/.cache/hypr-theme";
  jsonFormat = pkgs.formats.json {};
in {
  config = lib.mkIf cfgEnabled {
    xdg.configFile."waybar/config" = {
      force = true;
      source = jsonFormat.generate "waybar-config.json" [
        {
          layer = "top";
          position = "top";
          mode = "dock";
          exclusive = true;
          passthrough = false;
          reload_style_on_change = true;
          height = 38;
          spacing = 0;
          modules-left = ["group/leaf-inverse"];
          modules-center = [
            "group/pill#1"
            "group/pill-in#center"
            "group/pill#2"
          ];
          modules-right = ["group/leaf"];
          "group/leaf-inverse" = {
            orientation = "inherit";
            modules = [
              "hyprland/workspaces"
              "wlr/taskbar"
            ];
          };
          "group/pill#1" = {
            orientation = "inherit";
            modules = [
              "cpu"
              "memory"
            ];
          };
          "group/pill-in#center" = {
            orientation = "inherit";
            modules = [
              "clock"
              "hyprland/window"
              "custom/keybindhint"
            ];
          };
          "group/pill#2" = {
            orientation = "inherit";
            modules = [
              "custom/wallchange"
              "custom/theme"
            ];
          };
          "group/leaf" = {
            orientation = "inherit";
            modules = [
              "privacy"
              "tray"
              "network"
              "bluetooth"
              "pulseaudio"
              "pulseaudio#microphone"
              "custom/swaync"
              "custom/power"
            ];
          };
          "hyprland/workspaces" = {
            all-outputs = true;
            active-only = false;
            on-click = "activate";
            disable-scroll = false;
            on-scroll-up = "hyprctl dispatch workspace -1";
            on-scroll-down = "hyprctl dispatch workspace +1";
            persistent-workspaces."*" = 10;
            format = "{icon}";
            format-icons = {
              "1" = "I";
              "2" = "II";
              "3" = "III";
              "4" = "IV";
              "5" = "V";
              "6" = "VI";
              "7" = "VII";
              "8" = "VIII";
              "9" = "IX";
              "10" = "X";
              urgent = "!";
              focused = "*";
              default = "o";
            };
          };
          "wlr/taskbar" = {
            format = "{icon}";
            icon-size = 18;
            tooltip-format = "{title}";
            on-click = "activate";
            on-click-middle = "close";
          };
          "hyprland/window" = {
            format = " {0}";
            separate-outputs = true;
            max-length = 70;
            rewrite = {
              "(.*)Mozilla Firefox" = "Firefox";
              "(.*)Google Chrome" = "Chrome";
              "(.*)Dolphin" = "Dolphin";
              "(.*)Visual Studio Code" = "Code";
              "(.*)Code - OSS" = "Code";
              "(.*)Spotify" = "Spotify";
              "(.*)Steam" = "Steam";
              "(.*)Discord" = "Discord";
            };
          };
          cpu = {
            format = " {usage}%";
            interval = 3;
          };
          memory = {
            format = " {percentage}%";
            interval = 3;
          };
          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "";
            format-icons.default = [
              ""
              ""
              ""
            ];
            on-click = "pavucontrol";
            on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
            on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
            scroll-step = 5;
          };
          "pulseaudio#microphone" = {
            format = "{format_source}";
            format-source = "";
            format-source-muted = "";
            on-click = "pavucontrol";
            on-click-middle = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          };
          network = {
            tooltip = true;
            format-wifi = "";
            format-ethernet = "󰈀";
            format-linked = "󰈀";
            format-disconnected = "󰖪";
            format-alt = " {bandwidthDownBytes}  {bandwidthUpBytes}";
            tooltip-format = "{ifname} {ipaddr}/{cidr}\nDown {bandwidthDownBytes}\nUp {bandwidthUpBytes}";
            interval = 2;
            on-click = "systemsettings kcm_networkmanagement";
          };
          bluetooth = {
            format = "";
            format-disabled = "";
            format-connected = " {num_connections}";
            tooltip-format = "{controller_alias}\n{num_connections} connected";
            tooltip-format-connected = "{controller_alias}\n{num_connections} connected\n\n{device_enumerate}";
            on-click = "systemsettings kcm_bluetooth";
          };
          privacy = {
            icon-spacing = 5;
            transition-duration = 250;
            modules = [
              {
                type = "screenshare";
                tooltip = true;
              }
              {
                type = "audio-in";
                tooltip = true;
              }
            ];
            ignore-monitor = true;
          };
          tray.spacing = 6;
          "custom/swaync" = {
            format = "";
            tooltip = true;
            tooltip-format = "Notifications";
            on-click = "swaync-client -t -sw";
            on-click-right = "swaync-client -d -sw";
          };
          "custom/keybindhint" = {
            format = "";
            tooltip = true;
            tooltip-format = "Keybinds";
            on-click = "hypr-shortcuts";
          };
          "custom/wallchange" = {
            format = "󰸉";
            tooltip = true;
            tooltip-format = "Random wallpaper";
            on-click = "hypr-wallpaper-picker --random";
            on-click-right = "hypr-wallpaper-picker";
            interval = 86400;
          };
          "custom/theme" = {
            format = "";
            tooltip = true;
            tooltip-format = "Re-apply wallpaper colors";
            on-click = "hypr-theme-apply --init";
            interval = 86400;
          };
          "custom/power" = {
            format = "";
            tooltip = true;
            tooltip-format = "Lock";
            on-click = "hypr-lock";
            on-click-right = "hyprctl dispatch exit";
            interval = 86400;
          };
          clock = {
            format = "{:%I:%M %p}";
            format-alt = "{:%R  %d.%m.%y}";
            tooltip-format = "<span>{calendar}</span>";
            calendar = {
              mode = "month";
              mode-mon-col = 3;
              on-scroll = 1;
              on-click-right = "mode";
            };
          };
        }
      ];
    };

    xdg.configFile."waybar/style.css" = {
      force = true;
      text = ''
        @define-color bar-bg #191724;
        @define-color main-bg #26233a;
        @define-color main-fg #e0def4;
        @define-color wb-act-bg #9ccfd8;
        @define-color wb-act-fg #191724;
        @define-color wb-hvr-bg #403d52;
        @define-color wb-hvr-fg #e0def4;
        @define-color border-color #9ccfd8;
        @define-color muted #908caa;
        @define-color warning #f6c177;
        @import url("${themeStateDir}/waybar.css");

        * {
          font-family: "JetBrainsMono Nerd Font", sans-serif;
          font-size: 13px;
          border: none;
          min-height: 0;
          box-shadow: none;
          text-shadow: none;
        }

        window#waybar {
          background: alpha(@bar-bg, 0.70);
          color: @main-fg;
        }

        .module {
          color: @main-fg;
        }

        #leaf,
        #leaf-inverse,
        #pill-in,
        #pill {
          background-color: alpha(@main-bg, 0.88);
          border: 1px solid alpha(@border-color, 0.28);
          padding: 0 14px;
          margin: 5px 8px;
        }

        window#waybar.top #pill {
          border-radius: 10pt;
        }

        window#waybar.top #pill-in {
          border-radius: 0 0 10pt 10pt;
          background-color: alpha(@bar-bg, 0.78);
          border-color: alpha(@border-color, 0.42);
          margin: 0 1em 0.3em;
        }

        window#waybar.top #leaf {
          border-radius: 10pt 0 10pt 0;
          margin-right: 0;
        }

        window#waybar.top #leaf-inverse {
          border-radius: 0 10pt 0 10pt;
          margin-left: 0;
        }

        #workspaces,
        #taskbar {
          padding: 0;
        }

        #workspaces button {
          color: @main-fg;
          padding: 0 5px;
          margin: 4px 1px;
          border-radius: 10pt;
          transition: all 0.25s cubic-bezier(.55, -0.68, .48, 1.68);
        }

        #workspaces button.active {
          color: @wb-act-fg;
          background: @wb-act-bg;
          padding-left: 16px;
          padding-right: 16px;
          margin-left: 4px;
          margin-right: 4px;
        }

        #workspaces button:hover,
        #taskbar button:hover {
          color: @wb-hvr-fg;
          background: @wb-hvr-bg;
        }

        #taskbar button {
          color: @main-fg;
          padding: 0 5px;
          margin: 4px 1px;
          border-radius: 10pt;
        }

        #taskbar button.active {
          color: @wb-act-fg;
          background: @wb-act-bg;
        }

        #window,
        #cpu,
        #memory,
        #pulseaudio,
        #pulseaudio.microphone,
        #network,
        #bluetooth,
        #privacy,
        #tray,
        #custom-swaync,
        #custom-keybindhint,
        #custom-wallchange,
        #custom-theme,
        #custom-power,
        #clock,
        #battery {
          padding: 0 6px;
          margin: 0 2px;
        }

        #clock {
          color: @warning;
          font-weight: 700;
        }

        tooltip {
          background: @main-bg;
          color: @main-fg;
          border: 1px solid @border-color;
          border-radius: 10px;
        }

        menu {
          background-color: @main-bg;
        }

        menu menuitem {
          transition: 0.25s;
        }

        menu menuitem:hover {
          background-color: @wb-act-bg;
          color: @wb-act-fg;
        }
      '';
    };
  };
}
