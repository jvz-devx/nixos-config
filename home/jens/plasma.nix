# KDE Plasma configuration via plasma-manager
{ pkgs, ... }: {
  programs.plasma = {
    enable = true;

    # Workspace appearance
    workspace = {
      clickItemTo = "select"; # Single-click to select (double-click to open)
      lookAndFeel = "org.kde.breezedark.desktop";
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };
      iconTheme = "Papirus-Dark";
      # TODO: Uncomment to set wallpaper
      # wallpaper = "${pkgs.kdePackages.plasma-workspace-wallpapers}/share/wallpapers/Mountain/contents/images/5120x2880.png";
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
              launchers = [
                "applications:org.kde.dolphin.desktop"  # File manager
                "applications:org.kde.konsole.desktop"  # Terminal
                "applications:google-chrome.desktop"    # Chrome browser
                "applications:vesktop.desktop"          # Vesktop (Discord with Vencord)
                "applications:cursor.desktop"           # Cursor IDE
              ];
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
        "show-on-mouse-pos" = "Meta+V"; # Clipboard on Meta+V
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
      "launch-krunner" = {
        name = "Launch KRunner";
        key = "Meta+Space";
        command = "qdbus org.kde.krunner /App display";
      };
    };

    # Power management (important for gaming laptop!)
    powerdevil = {
      AC = {
        powerButtonAction = "lockScreen";
        autoSuspend.action = "nothing"; # Never suspend when plugged in
        turnOffDisplay.idleTimeout = 3600; # 1 hour (screen off when plugged in)
        dimDisplay = {
          enable = true;
          idleTimeout = 3300; # 55 minutes (dim before screen turns off)
        };
      };
      battery = {
        powerButtonAction = "sleep";
        whenSleepingEnter = "standbyThenHibernate";
        autoSuspend = {
          action = "sleep";
          idleTimeout = 900; # 15 minutes
        };
        turnOffDisplay.idleTimeout = 300; # 5 minutes
        dimDisplay = {
          enable = true;
          idleTimeout = 120; # 2 minutes
        };
      };
      lowBattery = {
        powerButtonAction = "hibernate";
        whenLaptopLidClosed = "hibernate";
      };
    };

    # KWin (window manager)
    kwin = {
      edgeBarrier = 0; # Disable edge barriers
      cornerBarrier = false;

      # Enable some nice effects
      effects = {
        shakeCursor.enable = true;
        blur.enable = true;  # Enable blur effect for transparent windows
      };
    };

    # Screen locker
    kscreenlocker = {
      lockOnResume = true;
      timeout = 5; # Lock after 5 minutes
    };

    # Low-level config tweaks
    configFile = {
      # Disable Baloo file indexer (saves battery, reduces disk I/O)
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;

      # 4 virtual desktops
      kwinrc.Desktops.Number = {
        value = 4;
        immutable = true;
      };
      kwinrc.Desktops.Rows = 2;

      # Window decoration buttons (Windows style - min/max/close on right)
      kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "";
      kwinrc."org.kde.kdecoration2".ButtonsOnRight = "IAX";

      # Window rules for transparency (via kwinrulesrc)
      # Rule 1: Konsole transparency
      kwinrulesrc."1" = {
        Description = "Konsole transparency";
        wmclass = "konsole konsole";
        wmclassmatch = 1;
        opacity = 85;  # 85% opacity (15% transparent)
        opacityactive = 85;
        opacityinactive = 85;
      };
      # Rule 2: Cursor transparency
      kwinrulesrc."2" = {
        Description = "Cursor transparency";
        wmclass = "cursor cursor";
        wmclassmatch = 1;
        opacity = 90;  # 90% opacity (10% transparent)
        opacityactive = 90;
        opacityinactive = 90;
      };
      # Enable window rules
      kwinrulesrc.General.count = 2;
    };
  };
}

