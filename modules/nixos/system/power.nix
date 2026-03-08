# Power configuration for laptop - suspend, hibernate, lid actions, powertop
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.myConfig.system.power.enable = lib.mkEnableOption "Laptop power management (suspend, hibernate, lid actions)";

  config = lib.mkIf config.myConfig.system.power.enable {
    # Powertop auto-tune on boot for maximum power savings
    powerManagement.powertop.enable = true;

    # NOTE: thermald tested but worsened package C-states on ROG Strix G16
    # (4s polling prevents package idle, all PC states stuck at 0%)
    # NOTE: auto-cpufreq tested but conflicts with power-profiles-daemon
    # and removes the Fn keyboard shortcut for switching power profiles.

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
