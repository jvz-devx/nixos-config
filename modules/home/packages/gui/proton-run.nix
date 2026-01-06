{ pkgs, ... }: 
let
  # A transparent runner that uses standard Wine but wrapped in steam-run
  # for maximum compatibility. It respects existing WINEPREFIX if you are
  # launching from a specific game folder.
  proton-run = pkgs.writeShellScriptBin "proton-run" ''
    # Use a default prefix ONLY if none is set
    if [ -z "$WINEPREFIX" ]; then
      export WINEPREFIX="$HOME/.local/share/proton-run-prefix"
      mkdir -p "$WINEPREFIX"
    fi

    # Log execution for debugging
    echo "Running: $@ in $WINEPREFIX" >> /tmp/proton-run.log

    # We use standard wine (with WoW64 support) for maximum compatibility.
    # steam-run ensures all standard libraries (LD_LIBRARY_PATH) are available.
    # Note: Use wine-wayland if you prefer native Wayland, but standard wine is usually more stable.
    exec ${pkgs.steam-run}/bin/steam-run ${pkgs.wineWowPackages.stable}/bin/wine "$@"
  '';
in {
  home.packages = [ proton-run ];

  # Associate .exe and .msi files with our transparent runner
  xdg.desktopEntries.proton-run = {
    name = "Proton Run";
    exec = "${proton-run}/bin/proton-run %f";
    icon = "wine";
    terminal = true; # Open a terminal so you can see errors if it fails
    mimeType = [ "application/x-ms-dos-executable" "application/x-msi" ];
  };

  xdg.mimeApps.defaultApplications = {
    "application/x-ms-dos-executable" = [ "proton-run.desktop" ];
    "application/x-msi" = [ "proton-run.desktop" ];
  };
}
