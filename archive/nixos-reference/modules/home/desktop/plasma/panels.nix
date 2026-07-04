{osConfig, ...}: {
  programs.plasma.panels = [
    {
      location = "top";
      height = 32;
      floating = true;
      opacity = "translucent";
      screen = 0;
      widgets = [
        "org.kde.plasma.appmenu"
        "org.kde.plasma.pager"
        "org.kde.plasma.panelspacer"
        {
          digitalClock = {
            calendar.firstDayOfWeek = "monday";
            time.format = "24h";
          };
        }
        "org.kde.plasma.panelspacer"
        {
          systemTray.items.shown = [
            "org.kde.plasma.battery"
            "org.kde.plasma.bluetooth"
            "org.kde.plasma.networkmanagement"
            "org.kde.plasma.volume"
          ];
        }
      ];
    }
    {
      location = "bottom";
      height = 58;
      lengthMode = "fit";
      hiding = "autohide";
      floating = true;
      opacity = "translucent";
      screen = 0;
      widgets = [
        {
          kickoff.icon = "nix-snowflake-white";
        }
        {
          iconTasks.launchers =
            if osConfig.networking.hostName == "pc-02"
            then [
              "applications:org.kde.dolphin.desktop"
              "applications:google-chrome.desktop"
              "applications:vesktop.desktop"
              "applications:steam.desktop"
            ]
            else if osConfig.networking.hostName == "rog-strix"
            then [
              "applications:org.kde.dolphin.desktop"
              "applications:vesktop.desktop"
              "applications:youtube-music.desktop"
              "applications:dev.zed.Zed.desktop"
              "applications:google-chrome.desktop"
              "applications:steam.desktop"
            ]
            else [];
        }
      ];
    }
  ];
}
