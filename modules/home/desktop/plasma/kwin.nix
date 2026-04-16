{...}: {
  programs.plasma.kwin = {
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

  programs.plasma.configFile = {
    ksmserverrc.General.loginMode = "emptySession";
    kscreenlockerrc.Daemon.Timeout = 0;
    kscreenlockerrc.Daemon.Autolock = false;

    kglobalshortcutsrc."Global Shortcuts Portal".google-chrome = true;
    kglobalshortcutsrc."Global Shortcuts Portal"."com.google.Chrome" = true;
    kglobalshortcutsrc."Global Shortcuts Portal"."Google Chrome" = true;
    kglobalshortcutsrc."Global Shortcuts Portal".vesktop = true;
    kglobalshortcutsrc.GlobalShortcutsPortal.google-chrome = true;
    kglobalshortcutsrc.GlobalShortcutsPortal."com.google.Chrome" = true;
    kglobalshortcutsrc.GlobalShortcutsPortal.vesktop = true;

    plasmanotifyrc."Applications/google-chrome".Seen = true;
    plasmanotifyrc."Applications/vesktop".Seen = true;

    baloofilerc."Basic Settings"."Indexing-Enabled" = false;
    kdeglobals.KDE.SingleClick = false;
    kdeglobals."KFileDialog Settings"."Show hidden files" = {
      value = true;
      immutable = true;
    };

    dolphinrc.General.ShowHiddenFiles = {
      value = true;
      immutable = true;
    };
    dolphinrc.PreviewSettings.RemoteFiles = false;

    kwinrc.Desktops.Number = {
      value = 4;
      immutable = true;
    };
    kwinrc.Desktops.Rows = 2;
    kwinrc."org.kde.kdecoration2".ButtonsOnLeft = "";
    kwinrc."org.kde.kdecoration2".ButtonsOnRight = "IAX";
    kwinrc."org.kde.kdecoration2".theme = "__aurorae__svg__Nordic";
    "kcminputrc"."Libinput/1133/16511/Logitech G502".PointerAccelerationProfile = 1;
    "kcminputrc"."Libinput/12625/16405/ROYUAN Gaming Keyboard Mouse".PointerAccelerationProfile = 1;
    kwinrc.Tiling.padding = 4;
    kwinrc.Compositing.UnredirectFullscreen = true;
    kwinrc.Compositing.VSync = "none";
    kwinrc.Compositing.AllowTearing = true;
    kwinrc.Compositing.SuspendCompositingForFullscreen = true;
    kwinrc.Compositing.WindowsBlockCompositing = true;
    kwinrc.Compositing.GLPreferBufferSwap = "n";
    kwinrc.Compositing.GLTextureFilter = 0;
    kwinrc.Compositing.LatencyPolicy = "Low";
    kwinrc.blur.blurRadius = 25;
    kwinrc.blur.blurStrength = 3;
  };

  programs.plasma.dataFile."dolphin/view_properties/global/.directory" = {
    Dolphin = {
      ShowHiddenFiles = true;
      SortHiddenLast = false;
    };
  };
}
