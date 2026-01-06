{pkgs, ...}: {
  home.packages = with pkgs; [
    ytmdesktop
    vlc
  ];
}
