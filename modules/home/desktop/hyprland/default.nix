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
in {
  imports = [
    ./config-lua.nix
    ./lock-idle.nix
    ./scripts.nix
    ./theme.nix
    ./waybar.nix
  ];

  config = lib.mkIf cfgEnabled {
    home.packages = with pkgs; [
      brightnessctl
      cliphist
      dbus
      grim
      hypridle
      hyprlock
      hyprpicker
      hyprpolkitagent
      hyprsunset
      jq
      kdePackages.bluedevil
      kdePackages.systemsettings
      kitty
      networkmanagerapplet
      pavucontrol
      satty
      slurp
      swaynotificationcenter
      waybar
      wl-clipboard
    ];

    home.sessionVariables.TERMINAL = terminalCommand;
  };
}
