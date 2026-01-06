# Development GUI applications
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf (config.myConfig.programs.development.enable && config.myConfig.desktop.plasma.enable) {
    environment.systemPackages = with pkgs; let
      hasNvidia = config.myConfig.hardware.nvidia.enable or false;

      # Wrap Cursor to disable Electron's internal sandbox
      # This fixes "EROFS: read-only file system" errors when writing to settings.json
      cursor-wrapped = pkgs.symlinkJoin {
        name = "cursor-wrapped";
        paths = [code-cursor-fhs];
        buildInputs = [pkgs.makeWrapper];
        postBuild = ''
          wrapProgram $out/bin/cursor \
            --add-flags "--no-sandbox"
        '';
      };
    in
      [
        # Editors
        cursor-wrapped # Cursor IDE (with sandbox fix)

        # Network Tools
        wireshark # GUI packet analyzer

        # System Monitoring
        mission-center # Modern Task Manager for Linux
      ]
      ++ lib.optionals hasNvidia [
        gwe # GreenWithEnvy - NVIDIA overclocking/underclocking (GUI)
      ];
  };
}
