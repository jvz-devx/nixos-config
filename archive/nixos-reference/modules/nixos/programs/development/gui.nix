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
        vscode # Visual Studio Code

        # Network Tools
        wireshark # GUI packet analyzer

        # System Monitoring
        mission-center # Modern Task Manager for Linux

        # AI/LLM
        lmstudio # Local LLM experimentation
        t3-code # T3 Code - GUI for AI coding agents
      ]
      ++ lib.optionals hasNvidia [
        gwe # GreenWithEnvy - NVIDIA overclocking/underclocking (GUI)
      ];
  };
}
