# Desktop profile - base desktop functionality
# Enables common desktop features: Plasma, portals, audio, bluetooth, locale, boot, disk, maintenance
{
  config,
  lib,
  ...
}: {
  options.myConfig.profiles.desktop.enable = lib.mkEnableOption "Desktop profile (Plasma, portals, audio, bluetooth, locale, boot, disk, maintenance)";

  config = lib.mkIf config.myConfig.profiles.desktop.enable {
    myConfig.desktop.plasma.enable = true;
    myConfig.desktop.portals.enable = true;
    myConfig.hardware.audio.enable = true;
    myConfig.hardware.bluetooth.enable = true;
    myConfig.hardware.logitech.enable = true;
    myConfig.system.locale.enable = true;
    myConfig.system.boot.enable = true;
    myConfig.system.disk.enable = true;
    myConfig.services.maintenance.enable = true;
  };
}
