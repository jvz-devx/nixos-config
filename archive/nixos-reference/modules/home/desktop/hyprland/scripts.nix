{
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  hyprlandCfg = osConfig.myConfig.desktop.hyprland or {};
  cfgEnabled = hyprlandCfg.enable or false;
  terminalCommand = hyprlandCfg.terminal or "foot";
  browserCommandRaw = hyprlandCfg.browserCommand or "google-chrome-stable";
  browserCommand =
    if lib.hasInfix "||" browserCommandRaw
    then "google-chrome-stable"
    else browserCommandRaw;
  hyprlandPackage = osConfig.programs.hyprland.package or pkgs.hyprland;

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
          'Super + Space           Open Caelestia launcher' \
          'Super + /               Show this shortcut picker' \
          'Super + F1              Show this shortcut picker' \
          'Super + B               Open browser' \
          'Super + E               Open file manager' \
          'Super + F               Toggle fullscreen' \
          'Super + Shift + Space   Toggle floating' \
          'Super + Q               Close focused app' \
          'Super + Shift + Q       Open session menu' \
          'Super + Ctrl + L        Lock with Caelestia' \
          'Super + N               Open Caelestia sidebar' \
          'Super + K               Show Caelestia panels' \
          'Super + V               Clipboard history' \
          'Super + Shift + V       Clear clipboard history' \
          'Super + Shift + C       Pick color to clipboard' \
          'Ctrl + Super + Shift + R Kill Caelestia shell' \
          'Ctrl + Super + Alt + R  Restart Caelestia shell' \
          'Alt + Tab               Native Hyprland window cycle' \
          'Alt + Shift + Tab       Native Hyprland reverse window cycle' \
          'Super + Arrow           Focus tiled window' \
          'Super + Shift + Arrow   Move tiled window' \
          'Super + 1-0             Switch workspace' \
          'Super + Alt + 1-0       Move window to workspace' \
          'Print                   Caelestia screenshot' \
          'Super + Shift + S       Caelestia frozen region screenshot to clipboard' \
          'XF86 Media/Brightness   Caelestia media and brightness controls' \
          'Super + Mouse Left      Drag window' \
          'Super + Mouse Right     Resize window' \
          'Copy shortcut list      Copy this list to clipboard'
      }

      selection="$(shortcut_list | fuzzel --dmenu --prompt 'Shortcut > ' --width 76 --lines 30)"

      case "$selection" in
        "Super + Return"*) hyprctl dispatch exec "${terminalCommand}" ;;
        "Super + Space"*) hyprctl dispatch global caelestia:launcher ;;
        "Super + /"* | "Super + F1"*) hyprctl dispatch exec hypr-shortcuts ;;
        "Super + B"*) hyprctl dispatch exec "${browserCommand}" ;;
        "Super + E"*) hyprctl dispatch exec dolphin ;;
        "Super + F"*) hyprctl dispatch fullscreen ;;
        "Super + Shift + Space"*) hyprctl dispatch togglefloating ;;
        "Super + Q"*) hyprctl dispatch killactive ;;
        "Super + Shift + Q"*) hyprctl dispatch global caelestia:session ;;
        "Super + Ctrl + L"*) hyprctl dispatch global caelestia:lock ;;
        "Super + N"*) hyprctl dispatch global caelestia:sidebar ;;
        "Super + K"*) hyprctl dispatch global caelestia:showall ;;
        "Super + V"*) hyprctl dispatch exec "sh -lc 'cliphist list | fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy'" ;;
        "Super + Shift + V"*) hyprctl dispatch exec "cliphist wipe" ;;
        "Super + Shift + C"*) hyprctl dispatch exec "hyprpicker -a" ;;
        "Ctrl + Super + Shift + R"*) hyprctl dispatch exec "qs -c caelestia kill" ;;
        "Ctrl + Super + Alt + R"*) hyprctl dispatch exec "systemctl --user restart caelestia.service" ;;
        "Alt + Tab"*) hyprctl dispatch cyclenext ;;
        "Alt + Shift + Tab"*) hyprctl dispatch cyclenext prev ;;
        "Print"*) hyprctl dispatch exec "caelestia screenshot" ;;
        "Super + Shift + S"*) hyprctl dispatch global caelestia:screenshotFreezeClip ;;
        "Copy shortcut list"*) shortcut_list | wl-copy ;;
        *) ;;
      esac
    '';
  };
in {
  config = lib.mkIf cfgEnabled {
    home.packages = [
      hypr-kwallet-start
      hypr-shortcuts
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
