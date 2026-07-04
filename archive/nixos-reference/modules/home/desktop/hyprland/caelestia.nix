{
  inputs,
  config,
  lib,
  osConfig,
  pkgs,
  ...
}: let
  hyprlandCfg = osConfig.myConfig.desktop.hyprland or {};
  cfgEnabled = hyprlandCfg.enable or false;
  system = pkgs.stdenv.hostPlatform.system;
  caelestiaBasePackage = inputs.caelestia-shell.packages.${system}.with-cli;
  caelestiaPackage = caelestiaBasePackage.overrideAttrs (old: {
    postPatch =
      (old.postPatch or "")
      + ''
                substituteInPlace modules/bar/components/Clock.qml \
                  --replace-fail 'StyledRect {
            id: root
        ' 'StyledRect {
            id: root

            MouseArea {
                anchors.fill: parent
                z: 1
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    const visibilities = Visibilities.getForActive();
                    visibilities.dashboard = !visibilities.dashboard;
                }
            }
        '
      '';
  });
  shellSettings = {
    bar.status.showBattery = false;
    general.apps = {
      terminal = ["foot"];
      audio = ["pavucontrol"];
      playback = ["mpv"];
      explorer = ["dolphin"];
    };
    paths.wallpaperDir = "~/Pictures/Wallpapers";
    services = {
      audioIncrement = 0.05;
      brightnessIncrement = 0.05;
      maxVolume = 1.0;
      useFahrenheit = false;
      weatherLocation = "51.765,5.51806";
    };
  };
  shellConfig = (pkgs.formats.json {}).generate "caelestia-shell.json" shellSettings;
in {
  config = lib.mkIf cfgEnabled {
    programs.caelestia = {
      enable = true;
      package = caelestiaPackage;
      systemd = {
        enable = true;
        target = "graphical-session.target";
      };
      settings = {};
      cli = {
        enable = true;
        settings.theme.enableGtk = false;
      };
    };

    systemd.user.services.caelestia.Unit.X-Restart-Triggers = [shellConfig];

    home.activation.seedCaelestiaShellConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
      config_dir="${config.home.homeDirectory}/.config/caelestia"
      config_file="$config_dir/shell.json"

      $DRY_RUN_CMD mkdir -p "$config_dir"
      if [ -L "$config_file" ] || [ ! -e "$config_file" ]; then
        $DRY_RUN_CMD rm -f "$config_file"
        $DRY_RUN_CMD install -m 0644 ${shellConfig} "$config_file"
      fi
    '';
  };
}
