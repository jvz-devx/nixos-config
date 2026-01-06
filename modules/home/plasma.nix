# KDE Plasma configuration via plasma-manager
# Shared Plasma module for all users
{
  pkgs,
  osConfig,
  lib,
  ...
}: let
  # This is the "virtual" font name all apps will use.
  # The toggle-font script will point this name to either Monocraft or Miracode.
  userFont = "GlobalUserFont";

  # Script to toggle between fonts instantly using fontconfig aliases
  toggle-font = pkgs.writeShellScriptBin "toggle-font" ''
        CONF_DIR="$HOME/.config/fontconfig/conf.d"
        CONF_FILE="$CONF_DIR/99-user-font.conf"
        mkdir -p "$CONF_DIR"

        # Determine current font and swap
        if grep -q "Monocraft Nerd Font" "$CONF_FILE" 2>/dev/null; then
          TARGET_FONT="Miracode"
        else
          TARGET_FONT="Monocraft Nerd Font"
        fi

        # Create the fontconfig alias
        rm -f "$CONF_FILE"
        cat > "$CONF_FILE" <<EOF
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>${userFont}</family>
        <prefer>
          <family>$TARGET_FONT</family>
        </prefer>
      </alias>
    </fontconfig>
    EOF

        # Update KDE configuration directly (so it persists and is ready for next login/reload)
        # Regular fonts (10pt)
        for key in font fixed menuFont toolBarFont activeFont; do
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key "$key" "$TARGET_FONT,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
        done

        # Small font (8pt)
        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "$TARGET_FONT,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

        # 1. Refresh font cache
        ${pkgs.fontconfig}/bin/fc-cache -f

        # 2. Notify User (Passive approach)
        ${pkgs.libnotify}/bin/notify-send "Font Switcher" "Switched to $TARGET_FONT.\nPlease log out and back in for full effect." -i font
  '';
in {
  home.packages = with pkgs; [
    # Theming (required for plasma.nix)
    bibata-cursors
    tela-icon-theme
    nordzy-icon-theme
    nordic

    # Scripts
    toggle-font
    libnotify
    fontconfig
    procps
    dbus

    # Fonts
    inter
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    monocraft
    miracode

    # KDE extras
    kdePackages.kde-gtk-config
    kdePackages.breeze-gtk
    kdePackages.breeze
    kdePackages.qtstyleplugin-kvantum
    kdePackages.qtmultimedia
    smart-video-wallpaper
  ];

  # This ensures the fontconfig directory exists and GlobalUserFont is initialized to Monocraft
  # We use 'force = true' to allow the script to overwrite it later, but provide the default here
  xdg.configFile."fontconfig/conf.d/99-user-font.conf" = {
    force = true;
    text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <alias>
          <family>${userFont}</family>
          <prefer>
            <family>Monocraft Nerd Font</family>
          </prefer>
        </alias>
      </fontconfig>
    '';
  };

  programs.plasma = {
    enable = true;
    overrideConfig = true; # Force plasma-manager to rewrite configs on rebuild

    # Workspace appearance
    workspace = {
      clickItemTo = "select";
      lookAndFeel = "Nordic-darker";
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };
      iconTheme = "Tela-black-dark";
      wallpaper = ../../assets/wallpaper/deyuin6-c7ad1dee-e0ae-423c-8e1a-bc4addf550e0.gif;
    };

    # Fonts
    fonts = {
      general = {
        family = userFont;
        pointSize = 10;
      };
      fixedWidth = {
        family = userFont;
        pointSize = 10;
      };
      small = {
        family = userFont;
        pointSize = 8;
      };
      toolbar = {
        family = userFont;
        pointSize = 10;
      };
      menu = {
        family = userFont;
        pointSize = 10;
      };
      windowTitle = {
        family = userFont;
        pointSize = 10;
      };
    };

    # Panel configuration - Two-panel layout
    panels = [
      # 1. Top Panel (Status Bar)
      {
        location = "top";
        height = 32;
        floating = true;
        opacity = "translucent";
        widgets = [
          # Global Menu (Application Menu) on the left
          "org.kde.plasma.appmenu"

          # Pager (Virtual Desktop Switcher) next to clock
          "org.kde.plasma.pager"

          # Spacer to center the clock
          "org.kde.plasma.panelspacer"

          # Digital Clock in the center
          {
            digitalClock = {
              calendar.firstDayOfWeek = "monday";
              time.format = "24h";
            };
          }

          # Spacer to push tray to the right
          "org.kde.plasma.panelspacer"

          # System Tray on the right
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
        ];
      }

      # 2. Bottom Panel (Floating Dock)
      {
        location = "bottom";
        # Thicker panel => visually larger corner radius when floating (more rounded "pill" look)
        height = 58;
        lengthMode = "fit"; # Fit content instead of full screen width
        hiding = "autohide";
        floating = true;
        opacity = "translucent";
        widgets = [
          {
            kickerdash.icon = "nix-snowflake-white";
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
                else [];
            };
          }
        ];
      }
    ];

    # Keyboard shortcuts
    shortcuts = {
      ksmserver = {
        "Lock Session" = ["Meta+Ctrl+L" "Screensaver"];
        "Log Out" = "Ctrl+Alt+Del";
      };
      kwin = {
        "Expose" = "Meta+Tab";
        "Overview" = "Meta+W";
        "Grid View" = "Meta+G";
        "Switch Window Down" = "Meta+J";
        "Switch Window Left" = "Meta+H";
        "Switch Window Right" = "Meta+L";
        "Switch Window Up" = "Meta+K";
        "Window Maximize" = "Meta+Up";
        "Window Minimize" = "Meta+Down";
        "Window Close" = "Meta+Q";
        "Window Quick Tile Left" = "Meta+Left";
        "Window Quick Tile Right" = "Meta+Right";
        "Walk Through Windows" = "Alt+Tab";
        "Window to Next Screen" = "Meta+Shift+Right";
        "Window to Previous Screen" = "Meta+Shift+Left";
      };
      plasmashell = {
        "show-on-mouse-pos" = "Meta+V";
        "activate task manager entry 1" = "Meta+1";
        "activate task manager entry 2" = "Meta+2";
        "activate task manager entry 3" = "Meta+3";
        "activate task manager entry 4" = "Meta+4";
        "activate task manager entry 5" = "Meta+5";
        "next activity" = "Meta+A";
        "previous activity" = "Meta+Shift+A";
      };
      "KDE Keyboard Layout Switcher" = {
        "Switch to Last-Used Keyboard Layout" = "Meta+Alt+L";
        "Switch to Next Keyboard Layout" = "Meta+Alt+K";
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
      "toggle-font" = {
        name = "Toggle Font (Monocraft/Miracode)";
        key = "Ctrl+Alt+PageUp";
        command = "${toggle-font}/bin/toggle-font";
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
        blur.enable = true;
        translucency.enable = true;
        wobblyWindows.enable = true;
        dimInactive.enable = true;
      };
    };

    # Screen locker
    kscreenlocker = {
      lockOnResume = true;
      timeout = 60;
    };

    # Low-level config tweaks
    configFile = {
      # Disable session restoration (prevents apps like Chrome from autostarting)
      ksmserverrc.General.loginMode = "emptySession";

      # Global Shortcuts Portal permissions (prevents annoying prompts after reboot)
      kglobalshortcutsrc."Global Shortcuts Portal".google-chrome = true;
      kglobalshortcutsrc."Global Shortcuts Portal"."com.google.Chrome" = true;
      kglobalshortcutsrc."Global Shortcuts Portal"."Google Chrome" = true;
      kglobalshortcutsrc."Global Shortcuts Portal".vesktop = true;
      kglobalshortcutsrc.GlobalShortcutsPortal.google-chrome = true;
      kglobalshortcutsrc.GlobalShortcutsPortal."com.google.Chrome" = true;
      kglobalshortcutsrc.GlobalShortcutsPortal.vesktop = true;

      # Mark notifications as seen
      plasmanotifyrc."Applications/google-chrome".Seen = true;
      plasmanotifyrc."Applications/vesktop".Seen = true;

      # Disable Baloo file indexer
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;

      # General settings
      kdeglobals.General.widgetStyle = "kvantum";
      kdeglobals.KDE.SingleClick = false;

      # Fix for FTP "maximum number of clients" error
      # Disables remote previews to reduce concurrent connections
      dolphinrc.PreviewSettings.RemoteFiles = false;

      # 4 virtual desktops
      kwinrc.Desktops.Number = {
        value = 4;
        immutable = true;
      };
      kwinrc.Desktops.Rows = 2;

      # Window decoration buttons
      kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "";
      kwinrc."org.kde.kdecoration2".ButtonsOnRight = "IAX";
      kwinrc."org.kde.kdecoration2".theme = "__aurorae__svg__Nordic";

      # Mouse Settings
      "kcminputrc"."Libinput/1133/16511/Logitech G502".PointerAccelerationProfile = 1;
      "kcminputrc"."Libinput/12625/16405/ROYUAN Gaming Keyboard Mouse".PointerAccelerationProfile = 1;

      # Tiling
      kwinrc.Tiling.padding = 4;

      # Gaming optimizations
      kwinrc.Compositing.UnredirectFullscreen = true;
      kwinrc.Compositing.VSync = "none";
      kwinrc.Compositing.AllowTearing = true;
      kwinrc.Compositing.SuspendCompositingForFullscreen = true;
      kwinrc.Compositing.WindowsBlockCompositing = true;
      kwinrc.Compositing.GLPreferBufferSwap = "a";
      kwinrc.Compositing.GLTextureFilter = 0;

      # KWin Blur effect tuning (Plasma 6 uses [blur])
      kwinrc.blur.blurRadius = 25;
      kwinrc.blur.blurStrength = 3;

      # Theme settings
      plasmarc."PlasmaTheme"."blurEnabled" = true;
      plasmarc."PlasmaTheme"."transparencyEnabled" = true;
      plasmarc."PlasmaTheme"."backgroundContrastEnabled" = false;
      plasmarc."Theme"."name" = "Nordic-darker";
      plasmarc.Wallpapers.usersWallpapers = "${../../assets/wallpaper/deyuin6-c7ad1dee-e0ae-423c-8e1a-bc4addf550e0.gif}";
    };
  };

  # Enable Kvantum
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "kvantum";
  };

  # Kvantum theme configuration
  xdg.configFile."Kvantum/kvantum.kvconfig" = {
    force = true;
    text = ''
      [General]
      theme=Nordic-Darker
    '';
  };

  # Symlink the entire Nordic-Darker theme directory for Kvantum
  xdg.configFile."Kvantum/Nordic-Darker".source = "${pkgs.nordic}/share/Kvantum/Nordic-Darker";

  # NOTE: Cursor settings are NOT managed by Nix to avoid conflicts with
  # Cursor's internal file locking and sandbox caching.
  # Set your fonts manually in Cursor: Ctrl+, then search for "font"
  # Recommended: editor.fontFamily = "GlobalUserFont, JetBrainsMono Nerd Font, monospace"
}
