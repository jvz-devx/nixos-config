# Power configuration for laptop - suspend, hibernate, lid actions
{
  config,
  lib,
  ...
}: {
  options.myConfig.system.power.enable = lib.mkEnableOption "Laptop power management (suspend, hibernate, lid actions)";

  config = lib.mkIf config.myConfig.system.power.enable {
    # Logind settings for lid/power button
    services.logind.settings = {
      Login = {
        # Lid close behavior
        HandleLidSwitch = "suspend";
        HandleLidSwitchExternalPower = "ignore";
        HandleLidSwitchDocked = "ignore";

        # Power button
        HandlePowerKey = "poweroff";
        HandlePowerKeyLongPress = "poweroff";
      };
    };

    # Systemd sleep settings
    systemd.sleep.extraConfig = ''
      AllowSuspend=yes
      AllowHibernation=yes
      AllowSuspendThenHibernate=yes
      AllowHybridSleep=yes
    '';
  };
}
