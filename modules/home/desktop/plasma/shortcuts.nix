{...}: {
  programs.plasma.shortcuts = {
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

  programs.plasma.hotkeys.commands = {
    "launch-konsole" = {
      name = "Launch Konsole";
      key = "Meta+Return";
      command = "konsole";
    };
    "launch-konsole-alt" = {
      name = "Launch Konsole (Ctrl+Alt+T)";
      key = "Ctrl+Alt+T";
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
}
