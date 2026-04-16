{...}: {
  programs.plasma = {
    enable = true;
    overrideConfig = true;

    powerdevil = {
      AC = {
        powerButtonAction = "lockScreen";
        autoSuspend.action = "nothing";
        turnOffDisplay.idleTimeout = "never";
        dimDisplay.enable = false;
      };
      battery = {
        powerButtonAction = "sleep";
        whenSleepingEnter = "standbyThenHibernate";
        autoSuspend = {
          action = "sleep";
          idleTimeout = 900;
        };
        turnOffDisplay.idleTimeout = 300;
        dimDisplay = {
          enable = true;
          idleTimeout = 120;
        };
      };
      lowBattery = {
        powerButtonAction = "hibernate";
        whenLaptopLidClosed = "hibernate";
      };
    };

    kscreenlocker = {
      lockOnResume = false;
      timeout = null;
    };
  };
}
