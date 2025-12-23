# KDE Plasma configuration via plasma-manager
# Shared Plasma module for all users
{ pkgs, osConfig, ... }: {
  programs.plasma = {
    enable = true;

    # Workspace appearance
    workspace = {
      clickItemTo = "select";
      lookAndFeel = "org.kde.breezedark.desktop";
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };
      iconTheme = "Papirus-Dark";
    };

    # Fonts
    fonts = {
      general = {
        family = "Inter";
        pointSize = 10;
      };
      fixedWidth = {
        family = "JetBrainsMono Nerd Font";
        pointSize = 10;
      };
    };

    # Panel configuration - Modern bottom panel
    panels = [
      {
        location = "bottom";
        height = 44;
        hiding = "none";
        floating = true;
        widgets = [
          {
            kickoff = {
              sortAlphabetically = true;
              icon = "nix-snowflake-white";
            };
          }
          {
            iconTasks = {
              launchers =
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
                  "applications:cursor.desktop"
                  "applications:google-chrome.desktop"
                  "applications:steam.desktop"
                ]
                else [ ];
            };
          }
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.battery"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.volume"
              ];
            };
          }
          {
            digitalClock = {
              calendar.firstDayOfWeek = "monday";
              time.format = "24h";
            };
          }
          "org.kde.plasma.showdesktop"
        ];
      }
    ];

    # Keyboard shortcuts
    shortcuts = {
      ksmserver = {
        "Lock Session" = ["Meta+Ctrl+L" "Screensaver"];
      };
      kwin = {
        "Expose" = "Meta+Tab";
        "Overview" = "Meta+W";
        "Switch Window Down" = "Meta+J";
        "Switch Window Left" = "Meta+H";
        "Switch Window Right" = "Meta+L";
        "Switch Window Up" = "Meta+K";
        "Window Maximize" = "Meta+Up";
        "Window Minimize" = "Meta+Down";
        "Window Close" = "Meta+Q";
      };
      plasmashell = {
        "show-on-mouse-pos" = "Meta+V";
      };
    };

    # Hotkeys for launching apps
    hotkeys.commands = {
      "launch-konsole" = {
        name = "Launch Konsole";
        key = "Meta+Return";
        command = "konsole";
      };
      "launch-dolphin" = {
        name = "Launch Dolphin";
        key = "Meta+E";
        command = "dolphin";
      };
      "launch-rofi" = {
        name = "Launch Rofi";
        key = "Meta+Space";
        command = "rofi -show drun";
      };
    };

    # Power management
    powerdevil = {
      AC = {
        powerButtonAction = "lockScreen";
        autoSuspend.action = "nothing";
        turnOffDisplay.idleTimeout = 3600;
        dimDisplay = {
          enable = true;
          idleTimeout = 3300;
        };
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

    # KWin (window manager)
    kwin = {
      edgeBarrier = 0;
      cornerBarrier = false;
      effects = {
        shakeCursor.enable = true;
        blur.enable = false;
      };
    };

    # Screen locker
    kscreenlocker = {
      lockOnResume = true;
      timeout = 5;
    };

    # Low-level config tweaks
    configFile = {
      # Disable Baloo file indexer
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;

      # 4 virtual desktops
      kwinrc.Desktops.Number = {
        value = 4;
        immutable = true;
      };
      kwinrc.Desktops.Rows = 2;

      # Window decoration buttons
      kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "";
      kwinrc."org.kde.kdecoration2".ButtonsOnRight = "IAX";

      # Gaming optimizations
      kwinrc.Compositing.UnredirectFullscreen = true;
      kwinrc.Compositing.VSync = "none";
      kwinrc.Compositing.AllowTearing = true;
      kwinrc.Compositing.SuspendCompositingForFullscreen = true;
      kwinrc.Compositing.WindowsBlockCompositing = true;
      kwinrc.Compositing.GLPreferBufferSwap = "a";
      kwinrc.Compositing.GLTextureFilter = 0;
    };
  };
}


