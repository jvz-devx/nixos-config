{...}: {
  system.defaults = {
    NSGlobalDomain = {
      AppleShowAllExtensions = true;
      InitialKeyRepeat = 15;
      KeyRepeat = 2;
    };

    finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "Nlsv";
      ShowPathbar = true;
      ShowStatusBar = true;
    };

    dock = {
      autohide = true;
      autohide-delay = 0.0;
      autohide-time-modifier = 0.15;
      show-recents = false;
      tilesize = 48;
    };

    CustomUserPreferences = {
      "com.apple.WindowManager" = {
        EnableTilingByEdgeDrag = true;
        EnableTopTilingByEdgeDrag = true;
        EnableTilingOptionAccelerator = true;
        EnableTiledWindowMargins = false;
      };

      "com.knollsoft.Rectangle" = {
        resizeOnDirectionalMove = true;
        subsequentExecutionMode = 0;
      };

      "com.jordanbaird.Ice" = {
        HideApplicationMenus = false;
        SUAutomaticallyUpdate = false;
        SUEnableAutomaticChecks = false;
        SUHasLaunchedBefore = true;
        ShowOnScroll = false;
        UseIceBar = false;
      };
    };
  };
}
