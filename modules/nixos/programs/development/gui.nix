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
    in
      [
        # Editors
        zed-editor # Zed IDE

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
