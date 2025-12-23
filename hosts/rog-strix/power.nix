# Power configuration for laptop - suspend, hibernate, lid actions
{ ... }: {
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
}


