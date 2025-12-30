# KDE Plasma configuration via plasma-manager
# Shared Plasma module for all users
{ pkgs, osConfig, lib, ... }: {
  programs.plasma = {
    enable = true;

    # Workspace appearance
    workspace = {
      clickItemTo = "select";
      lookAndFeel = "Nordic-darker";
      cursor = {
        theme = "Bibata-Modern-Classic";
        size = 24;
      };
      iconTheme = "Nordzy-dark"; # Updated from Tela-dark
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

    # Panel configuration - Two-panel layout with Panel Colorizer
    panels = [
      # 1. Top Panel (Status Bar)
      {
        location = "top";
        height = 32;
        floating = true;
        opacity = "translucent";
        widgets = [
          # Panel Colorizer (first widget recommended)
          "luisbocanegra.panelcolorizer"
          
          # Global Menu (Application Menu) on the left
          "org.kde.plasma.appmenu"
          
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
        # Thicker panel => visually larger corner radius when floating (more rounded “pill” look)
        height = 58;
        hiding = "autohide";
        floating = true;
        opacity = "translucent";
        widgets = [
          # Panel Colorizer
          "luisbocanegra.panelcolorizer"

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

      # Disable Baloo file indexer
      baloofilerc."Basic Settings"."Indexing-Enabled" = false;
      
      # Konsole
      "konsolerc"."Desktop Entry"."DefaultProfile" = "Default.profile";
      "konsolerc"."Favorite Profiles"."Favorites" = "Default.profile";

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

      # Panel Colorizer settings (global defaults)
      "panelcolorizerrc"."General"."bgOpacity" = 0; # Fully transparent base
      "panelcolorizerrc"."General"."bgBlur" = true;
      "panelcolorizerrc"."General"."bgRadius" = 24; # More rounded
      "panelcolorizerrc"."General"."bgMargin" = 8;  # Margin for floating effect
      "panelcolorizerrc"."General"."bgEnabled" = true;
      "panelcolorizerrc"."General"."bgCustomColor" = false;
    };
  };

  # Enable Kvantum
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
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

  # Konsole Profile
  xdg.dataFile."konsole/Default.profile".text = ''
    [Appearance]
    ColorScheme=Nordic
    Font=JetBrainsMono Nerd Font,10,-1,5,50,0,0,0,0,0
    Blur=true
    Opacity=0.85

    [General]
    Name=Default
    Parent=FALLBACK

    [Scrolling]
    HistoryMode=2
    HistorySize=10000

    [Terminal Features]
    BlinkingCursorEnabled=true
  '';

  # Nordic Konsole Color Scheme
  xdg.dataFile."konsole/Nordic.colorscheme".text = ''
    [Background]
    Color=46,52,64

    [BackgroundIntense]
    Color=59,66,82

    [Color0]
    Color=59,66,82

    [Color0Intense]
    Color=76,86,106

    [Color1]
    Color=191,97,106

    [Color1Intense]
    Color=191,97,106

    [Color2]
    Color=163,190,140

    [Color2Intense]
    Color=163,190,140

    [Color3]
    Color=235,203,139

    [Color3Intense]
    Color=235,203,139

    [Color4]
    Color=129,161,193

    [Color4Intense]
    Color=129,161,193

    [Color5]
    Color=180,142,173

    [Color5Intense]
    Color=180,142,173

    [Color6]
    Color=136,192,208

    [Color6Intense]
    Color=143,188,187

    [Color7]
    Color=229,233,240

    [Color7Intense]
    Color=236,239,244

    [Foreground]
    Color=216,222,233

    [ForegroundIntense]
    Color=236,239,244

    [General]
    Description=Nordic
    Opacity=0.85
    Wallpaper=
  '';

  xdg.configFile."Kvantum/Nordic-Darker/Nordic-Darker.kvconfig" = {
    force = true;
    text = ''
      [%General]
    author=Eliver Lara
    comment=A dark theme created using the awesome Nord color pallete. 
    x11drag=menubar_and_primary_toolbar
    alt_mnemonic=true
    left_tabs=true
    attach_active_tab=true
    mirror_doc_tabs=true
    group_toolbar_buttons=false
    toolbar_item_spacing=1
    toolbar_interior_spacing=3
    spread_progressbar=true
    composite=true
    menu_shadow_depth=5
    menu_separator_height=6
    tooltip_shadow_depth=6
    splitter_width=4
    scroll_width=6
    scroll_arrows=false
    scroll_min_extent=60
    slider_width=2
    slider_handle_width=18
    slider_handle_length=18
    center_toolbar_handle=true
    check_size=14
    textless_progressbar=false
    progressbar_thickness=2
    menubar_mouse_tracking=true
    toolbutton_style=1
    double_click=false
    translucent_windows=true
    blurring=true
    popup_blurring=true
    vertical_spin_indicators=false
    spin_button_width=32
    fill_rubberband=false
    merge_menubar_with_toolbar=true
    small_icon_size=16
    large_icon_size=32
    button_icon_size=16
    toolbar_icon_size=22
    combo_as_lineedit=true
    animate_states=false
    button_contents_shift=false
    combo_menu=true
    hide_combo_checkboxes=true
    combo_focus_rect=true
    groupbox_top_label=true
    inline_spin_indicators=false
    joined_inactive_tabs=false
    layout_spacing=6
    layout_margin=4
    scrollbar_in_view=true
    transient_scrollbar=true
    transient_groove=false
    submenu_overlap=0
    tooltip_delay=-1
    tree_branch_line=true
    dark_titlebar=true
    opaque=konsole,QMPlay2,kaffeine,kmplayer,subtitlecomposer,kdenlive,vlc,avidemux,avidemux2_qt4,avidemux3_qt4,avidemux3_qt5,kamoso,QtCreator,VirtualBox,trojita,dragon,digikam
    reduce_window_opacity=18
    scrollable_menu=false
    submenu_delay=250
    no_inactiveness=false
    no_window_pattern=false
    reduce_menu_opacity=0
    respect_DE=true
    contrast=1.00
    dialog_button_layout=0
    intensity=1.00
    saturation=1.00

    [GeneralColors]
    window.color=#434c5e
    base.color=#3b4252
    alt.base.color=#2E353D78
    button.color=#3c4454
    light.color=#2e3440
    mid.light.color=#2e3440
    dark.color=#2e3440
    mid.color=#2e3440
    highlight.color=#4c566a
    inactive.highlight.color=#4c566a
    text.color=#d8dee9
    window.text.color=#d8dee9
    button.text.color=#d8dee9
    disabled.text.color=#d8dee978
    tooltip.text.color=#d8dee9
    highlight.text.color=#d8dee9
    link.color=#646464
    link.visited.color=#7f8c8d
    progress.indicator.text.color=#d8dee9

    [Hacks]
    transparent_ktitle_label=true
    transparent_dolphin_view=true
    transparent_pcmanfm_sidepane=true
    blur_translucent=true
    transparent_menutitle=true
    respect_darkness=true
    kcapacitybar_as_progressbar=true
    force_size_grip=true
    iconless_pushbutton=false
    iconless_menu=false
    disabled_icon_opacity=70
    lxqtmainmenu_iconsize=22
    normal_default_pushbutton=true
    single_top_toolbar=true
    tint_on_mouseover=0
    transparent_pcmanfm_view=true
    middle_click_scroll=false
    no_selection_tint=false
    opaque_colors=false
    scroll_jump_workaround=false
    '';
  };
}
