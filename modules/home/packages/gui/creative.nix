{pkgs, ...}: {
  home.packages = with pkgs; [
    obs-studio # Screen recorder/streaming
    mpv # Media player
    handbrake # Video transcoder
    audacity # Audio editing
    gimp # Image editing
    inkscape # Vector graphics
  ];
}
