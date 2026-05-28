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
    ./caelestia.nix
    ./config.nix
    ./scripts.nix
    ./terminal.nix
  ];

  config = lib.mkIf cfgEnabled {
    home.packages = with pkgs; [
      app2unit
      bluez
      brightnessctl
      cliphist
      dbus
      ddcutil
      fish
      foot
      fuzzel
      grim
      hyprpicker
      hyprpolkitagent
      jq
      kdePackages.bluedevil
      kdePackages.systemsettings
      kitty
      libnotify
      material-symbols
      networkmanagerapplet
      pavucontrol
      satty
      slurp
      starship
      swappy
      thunar
      thunar-volman
      wl-clipboard
      nerd-fonts.caskaydia-cove
    ];

    home.sessionVariables.TERMINAL = terminalCommand;
  };
}
