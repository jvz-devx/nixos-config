{pkgs, ...}: {
  home.packages = with pkgs; [
    vesktop # Discord with Vencord mod
    teams-for-linux
    parsec-bin # Remote desktop/game streaming
  ];
}
