{pkgs, ...}: {
  home.packages = with pkgs; [
    youtube-music
    vlc
    hypnotix
  ];

  xdg.desktopEntries.youtube-music = {
    name = "YouTube Music";
    exec = "pear-desktop %U";
    icon = "youtube-music";
    comment = "YouTube Music Desktop App";
    categories = ["Audio" "AudioVideo"];
    mimeType = ["x-scheme-handler/youtube-music"];
  };
}
