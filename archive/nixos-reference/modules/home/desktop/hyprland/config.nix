{
  inputs,
  lib,
  osConfig,
  ...
}: let
  hyprlandCfg = osConfig.myConfig.desktop.hyprland or {};
  cfgEnabled = hyprlandCfg.enable or false;
  monitors = hyprlandCfg.monitors or [",preferred,auto,1"];
  browserCommandRaw = hyprlandCfg.browserCommand or "google-chrome-stable";
  browserCommand =
    if lib.hasInfix "||" browserCommandRaw
    then "google-chrome-stable"
    else browserCommandRaw;
  caelestiaDots = inputs.caelestia-dots;

  monitorConfig = lib.concatMapStringsSep "\n" (monitor: "monitor = ${monitor}") monitors;

  upstreamHyprFiles = [
    "animations"
    "decoration"
    "env"
    "general"
    "gestures"
    "group"
    "input"
    "keybinds"
    "misc"
    "rules"
    "scrolling"
  ];

  upstreamHyprConfig = lib.listToAttrs (map (name: {
      name = "hypr/hyprland/${name}.conf";
      value.source = "${caelestiaDots}/hypr/hyprland/${name}.conf";
    })
    upstreamHyprFiles);
in {
  config = lib.mkIf cfgEnabled {
    xdg.configFile =
      upstreamHyprConfig
      // {
        "hypr/hyprland.conf" = {
          force = true;
          text = ''
            # Managed by Home Manager.
            # Base config follows caelestia-dots/caelestia with local pc-02 overrides.

            $hypr = ~/.config/hypr
            $hl = $hypr/hyprland
            $cConf = ~/.config/caelestia

            source = $hypr/scheme/default.conf
            source = $hypr/variables.conf
            source = $cConf/hypr-vars.conf

            monitor = , preferred, auto, 1

            source = $hl/env.conf
            source = $hl/general.conf
            source = $hl/input.conf
            source = $hl/misc.conf
            source = $hl/animations.conf
            source = $hl/decoration.conf
            source = $hl/group.conf
            source = $hl/execs.conf
            source = $hl/rules.conf
            source = $hl/gestures.conf
            source = $hl/keybinds.conf
            source = $hl/scrolling.conf

            source = $cConf/hypr-user.conf
          '';
        };

        "hypr/variables.conf" = {
          source = "${caelestiaDots}/hypr/variables.conf";
        };

        "hypr/scheme/default.conf" = {
          source = "${caelestiaDots}/hypr/scheme/default.conf";
        };

        "hypr/scripts/wsaction.fish" = {
          source = "${caelestiaDots}/hypr/scripts/wsaction.fish";
          executable = true;
        };

        "hypr/hyprland/execs.conf" = {
          force = true;
          text = ''
            # Managed by Home Manager.
            # Keep NixOS/KDE auth pieces and start Caelestia through its HM systemd unit.

            exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP
            exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_SESSION_DESKTOP
            exec-once = systemctl --user start graphical-session.target

            exec-once = hypr-kwallet-start
            exec-once = hyprpolkitagent

            exec-once = wl-paste --type text --watch cliphist store
            exec-once = wl-paste --type image --watch cliphist store
            exec-once = mpris-proxy

            exec-once = caelestia resizer -d
          '';
        };

        "caelestia/hypr-vars.conf" = {
          force = true;
          text = ''
            # Managed by Home Manager.

            $terminal = foot
            $browser = ${browserCommand}
            $editor = codium
            $fileExplorer = dolphin

            $kbTerminal = Super, Return
            $kbBrowser = Super, B
            $kbFileExplorer = Super, E
            $kbSession = Super+Shift, Q
            $kbShowSidebar = Super, N
            $kbClearNotifs = Super+Shift, N
            $kbShowPanels = Super, K
            $kbLock = Super+Ctrl, L
            $kbRestoreLock = Super+Alt, L
            $kbWindowFullscreen = Super, F
            $kbToggleWindowFloating = Super+Shift, Space
            $kbCloseWindow = Super, Q
          '';
        };

        "caelestia/hypr-user.conf" = {
          force = true;
          text = ''
            # Managed by Home Manager.
            # Local machine overrides are sourced after upstream Caelestia config.

            ${monitorConfig}

            env = NIXOS_OZONE_WL, 1

            general {
                allow_tearing = true

                snap {
                    enabled = true
                }
            }

            misc {
                vrr = 3
                focus_on_activate = true
                allow_session_lock_restore = true
            }

            # Caelestia shell shortcuts with local muscle memory.
            bind = Super, Space, global, caelestia:launcher
            bind = Super, slash, exec, hypr-shortcuts
            bind = Super, F1, exec, hypr-shortcuts
            unbind = Super+Shift, S
            bind = Super+Shift, S, global, caelestia:screenshotFreezeClip

            # Keep the existing cliphist picker flow instead of replacing it with shell clipboard state.
            unbind = Super, V
            unbind = Super+Alt, V
            bind = Super, V, exec, sh -lc 'cliphist list | fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy'
            bind = Super+Shift, V, exec, cliphist wipe

            # Hard gaming invariant: VRR stays enabled and games keep immediate/fullscreen handling.
            windowrule = content game, match:class ^(steam_app_[0-9]+)$
            windowrule = immediate true, match:class ^(steam_app_[0-9]+)$
            windowrule = allows_input true, match:class ^(steam_app_[0-9]+)$
            windowrule = no_shortcuts_inhibit true, match:class ^(steam_app_[0-9]+)$
            windowrule = idle_inhibit always, match:class ^(steam_app_[0-9]+)$

            windowrule = content game, match:class ^(gamescope)$
            windowrule = immediate true, match:class ^(gamescope)$
            windowrule = allows_input true, match:class ^(gamescope)$
            windowrule = no_shortcuts_inhibit true, match:class ^(gamescope)$
            windowrule = idle_inhibit always, match:class ^(gamescope)$
          '';
        };

        "caelestia/user-config.fish" = {
          force = true;
          text = "";
        };
      };
  };
}
