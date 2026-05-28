# Hyprland Wayland compositor
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  hyprlandPackages = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in {
  options.myConfig.desktop.hyprland = {
    enable = lib.mkEnableOption "Hyprland desktop session";

    monitors = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [",preferred,auto,1"];
      example = ["HDMI-A-1,3840x2160@119.88,0x0,1"];
      description = "Hyprland monitor declarations, without the leading `monitor =`.";
    };

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "kitty";
      description = "Terminal command used by the Hyprland session.";
    };

    browserCommand = lib.mkOption {
      type = lib.types.str;
      default = "google-chrome-stable || google-chrome";
      description = "Browser command used by Hyprland keybindings and shell widgets.";
    };
  };

  config = lib.mkIf config.myConfig.desktop.hyprland.enable {
    programs.hyprland = {
      enable = true;
      package = hyprlandPackages.hyprland;
      portalPackage = hyprlandPackages.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
    };

    security.pam.services.sddm.kwallet.enable = true;
    hardware.i2c.enable = lib.mkDefault true;

    programs.ssh = {
      startAgent = lib.mkDefault true;
      askPassword = lib.mkDefault (lib.getExe pkgs.kdePackages.ksshaskpass);
    };

    services.udev.packages = [
      pkgs.ddcutil
    ];

    environment.systemPackages =
      (with pkgs.kdePackages; [
        ksshaskpass
        kwallet
      ])
      ++ [
        pkgs.ddcutil
      ];
  };
}
