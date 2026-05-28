{
  config,
  lib,
  osConfig,
  ...
}: let
  hyprlandCfg = osConfig.myConfig.desktop.hyprland or {};
  cfgEnabled = hyprlandCfg.enable or false;
  terminalCommand = hyprlandCfg.terminal or "warp-terminal";
  browserCommand = hyprlandCfg.browserCommand or "google-chrome-stable || google-chrome";
  monitors = hyprlandCfg.monitors or [",preferred,auto,1"];

  luaString = value: builtins.toJSON value;
  monitorToLua = monitor: let
    parts = lib.splitString "," monitor;
    output = lib.elemAt parts 0;
    mode =
      if lib.length parts > 1
      then lib.elemAt parts 1
      else "preferred";
    position =
      if lib.length parts > 2
      then lib.elemAt parts 2
      else "auto";
    scale =
      if lib.length parts > 3
      then lib.elemAt parts 3
      else "1";
  in ''
    hl.monitor({
      output = ${luaString output},
      mode = ${luaString mode},
      position = ${luaString position},
      scale = ${luaString scale},
    })
  '';

  monitorConfig = lib.concatMapStringsSep "\n" monitorToLua monitors;
in {
  config = lib.mkIf cfgEnabled {
    xdg.configFile."hypr/hyprland.lua" = {
      force = true;
      text = ''
        -- Managed by Home Manager.

        ${monitorConfig}

        local mod = "SUPER"
        local terminal = ${luaString terminalCommand}
        local browser = ${luaString browserCommand}
        local launcher = "hypr-fuzzel"

        hl.env("NIXOS_OZONE_WL", "1")
        hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
        hl.env("QT_QPA_PLATFORM", "wayland;xcb")
        hl.env("GDK_BACKEND", "wayland,x11")
        hl.env("CLUTTER_BACKEND", "wayland")
        hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
        hl.env("XDG_SESSION_DESKTOP", "Hyprland")
        hl.env("XDG_SESSION_TYPE", "wayland")

        hl.on("hyprland.start", function()
          hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE")
          hl.exec_cmd("hypr-theme-apply --init --no-reload")
          hl.exec_cmd("hypridle")
          hl.exec_cmd("hypr-kwallet-start")
          hl.exec_cmd("hyprpolkitagent")
          hl.exec_cmd("hypr-swaync-start")
          hl.exec_cmd("hypr-shell-start")
          hl.exec_cmd("wl-paste --type text --watch cliphist store")
          hl.exec_cmd("wl-paste --type image --watch cliphist store")
        end)

        hl.config({
          input = {
            kb_layout = "us",
            follow_mouse = 2,
            sensitivity = 0,
            touchpad = {
              natural_scroll = true,
            },
          },

          general = {
            gaps_in = 5,
            gaps_out = 10,
            border_size = 2,
            col = {
              active_border = { colors = { "rgba(9ccfd8ee)", "rgba(c4a7e7ee)" }, angle = 45 },
              inactive_border = "rgba(403d5266)",
            },
            layout = "dwindle",
            allow_tearing = true,
            snap = {
              enabled = true,
            },
          },

          decoration = {
            rounding = 10,
            dim_special = 0.3,
            active_opacity = 0.90,
            inactive_opacity = 0.75,
            fullscreen_opacity = 1,
            shadow = {
              enabled = true,
              range = 18,
              render_power = 3,
              color = "rgba(00000066)",
            },
            blur = {
              enabled = true,
              size = 7,
              passes = 3,
              new_optimizations = true,
              ignore_opacity = true,
              special = true,
            },
          },

          animations = {
            enabled = true,
          },

          dwindle = {
            pseudotile = true,
            preserve_split = true,
            smart_split = true,
          },

          misc = {
            disable_hyprland_logo = true,
            disable_splash_rendering = true,
            focus_on_activate = true,
            vrr = 3,
            force_default_wallpaper = 0,
            allow_session_lock_restore = true,
          },

          debug = {
            vfr = true,
          },
        })

        hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0 })
        hl.layer_rule({ match = { namespace = "fuzzel" }, blur = true, ignore_alpha = 0 })
        hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0 })
        hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true, ignore_alpha = 0 })

        hl.window_rule({ match = { class = "^(fuzzel)$" }, float = true })
        hl.window_rule({ match = { class = "^(org\\.kde\\.polkit-kde-authentication-agent-1)$" }, float = true })
        hl.window_rule({ match = { class = "^(pavucontrol)$" }, float = true })
        hl.window_rule({ match = { title = "^Picture-in-Picture$" }, float = true, pin = true })
        hl.window_rule({
          match = { class = "^(steam_app_[0-9]+)$" },
          content = "game",
          fullscreen = true,
          sync_fullscreen = true,
          immediate = true,
          allows_input = true,
          no_shortcuts_inhibit = true,
        })
        hl.window_rule({
          match = { class = "^(gamescope)$" },
          content = "game",
          fullscreen = true,
          sync_fullscreen = true,
          immediate = true,
          allows_input = true,
          no_shortcuts_inhibit = true,
        })

        hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))
        hl.bind(mod .. " + Space", hl.dsp.exec_cmd(launcher))
        hl.bind(mod .. " + slash", hl.dsp.exec_cmd("hypr-shortcuts"))
        hl.bind(mod .. " + F1", hl.dsp.exec_cmd("hypr-shortcuts"))
        hl.bind(mod .. " + B", hl.dsp.exec_cmd(browser))
        hl.bind(mod .. " + W", hl.dsp.exec_cmd("hypr-wallpaper-picker"))
        hl.bind(mod .. " + SHIFT + W", hl.dsp.exec_cmd("hypr-wallpaper-picker --random"))
        hl.bind(mod .. " + E", hl.dsp.exec_cmd("dolphin"))
        hl.bind(mod .. " + F", hl.dsp.window.fullscreen({ action = "toggle" }))
        hl.bind(mod .. " + SHIFT + Space", hl.dsp.window.float({ action = "toggle" }))
        hl.bind(mod .. " + R", hl.dsp.exec_cmd("hyprctl reload"))
        hl.bind(mod .. " + Q", hl.dsp.window.close())
        hl.bind(mod .. " + SHIFT + Q", hl.dsp.exit())
        hl.bind(mod .. " + CTRL + L", hl.dsp.exec_cmd("hypr-lock"))
        hl.bind(mod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))
        hl.bind(mod .. " + V", hl.dsp.exec_cmd("sh -lc 'cliphist list | hypr-fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy'"))
        hl.bind(mod .. " + SHIFT + V", hl.dsp.exec_cmd("cliphist wipe"))
        hl.bind(mod .. " + C", hl.dsp.exec_cmd("hyprpicker -a"))
        hl.bind(mod .. " + CTRL + B", hl.dsp.exec_cmd("hypr-shell-start"))
        hl.bind(mod .. " + SHIFT + P", hl.dsp.exec_cmd("power-profile-toggle"))

        hl.bind("ALT + Tab", hl.dsp.exec_cmd("hyprctl --batch 'dispatch cyclenext; dispatch bringactivetotop'"))
        hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("hyprctl --batch 'dispatch cyclenext prev; dispatch bringactivetotop'"))

        hl.bind(mod .. " + left", hl.dsp.focus({ direction = "left" }))
        hl.bind(mod .. " + right", hl.dsp.focus({ direction = "right" }))
        hl.bind(mod .. " + up", hl.dsp.focus({ direction = "up" }))
        hl.bind(mod .. " + down", hl.dsp.focus({ direction = "down" }))
        hl.bind(mod .. " + SHIFT + left", hl.dsp.window.move({ direction = "left" }))
        hl.bind(mod .. " + SHIFT + right", hl.dsp.window.move({ direction = "right" }))
        hl.bind(mod .. " + SHIFT + up", hl.dsp.window.move({ direction = "up" }))
        hl.bind(mod .. " + SHIFT + down", hl.dsp.window.move({ direction = "down" }))
        hl.bind(mod .. " + CTRL + Left", hl.dsp.resize(-80, 0))
        hl.bind(mod .. " + CTRL + Right", hl.dsp.resize(80, 0))
        hl.bind(mod .. " + CTRL + Up", hl.dsp.resize(0, -80))
        hl.bind(mod .. " + CTRL + Down", hl.dsp.resize(0, 80))
        hl.bind(mod .. " + T", hl.dsp.layout("togglesplit"))

        hl.bind(mod .. " + H", hl.dsp.focus({ direction = "left" }))
        hl.bind(mod .. " + J", hl.dsp.focus({ direction = "down" }))
        hl.bind(mod .. " + K", hl.dsp.focus({ direction = "up" }))
        hl.bind(mod .. " + L", hl.dsp.focus({ direction = "right" }))
        hl.bind(mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
        hl.bind(mod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))
        hl.bind(mod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
        hl.bind(mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))

        for i = 1, 10 do
          local key = tostring(i % 10)
          hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
          hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
        end

        hl.bind("Print", hl.dsp.exec_cmd("sh -lc 'mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" - | satty -f - --copy-command wl-copy -o ~/Pictures/Screenshots/%Y%m%d-%H%M%S.png'"))
        hl.bind(mod .. " + Print", hl.dsp.exec_cmd("sh -lc 'grim -g \"$(slurp)\" - | wl-copy'"))
        hl.bind(mod .. " + SHIFT + S", hl.dsp.exec_cmd("sh -lc 'mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" - | satty -f - --copy-command wl-copy -o ~/Pictures/Screenshots/%Y%m%d-%H%M%S.png'"))
        hl.bind(mod .. " + ALT + S", hl.dsp.exec_cmd("sh -lc 'mkdir -p ~/Pictures/Screenshots && grim -g \"$(slurp)\" ~/Pictures/Screenshots/$(date +%Y%m%d-%H%M%S).png'"))

        hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { repeating = true, locked = true })
        hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { repeating = true, locked = true })
        hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { repeating = true, locked = true })
        hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"), { repeating = true, locked = true })
        hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"), { repeating = true, locked = true })

        hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
        hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
      '';
    };
  };
}
