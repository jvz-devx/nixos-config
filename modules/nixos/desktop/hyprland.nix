# Hyprland Wayland compositor
{
  config,
  lib,
  ...
}: {
  options.myConfig.desktop.hyprland.enable = lib.mkEnableOption "Hyprland desktop session";

  config = lib.mkIf config.myConfig.desktop.hyprland.enable {
    programs.hyprland = {
      enable = true;
      xwayland.enable = true;
    };
  };
}
