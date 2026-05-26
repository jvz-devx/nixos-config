# Hyprland Wayland compositor
{
  config,
  lib,
  pkgs,
  ...
}: {
  options.myConfig.desktop.hyprland.enable = lib.mkEnableOption "Hyprland desktop session";

  config = lib.mkIf config.myConfig.desktop.hyprland.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };

    security.pam.services.sddm.kwallet.enable = true;

    programs.ssh = {
      startAgent = lib.mkDefault true;
      askPassword = lib.mkDefault (lib.getExe pkgs.kdePackages.ksshaskpass);
    };

    environment.systemPackages = with pkgs.kdePackages; [
      ksshaskpass
      kwallet
    ];
  };
}
