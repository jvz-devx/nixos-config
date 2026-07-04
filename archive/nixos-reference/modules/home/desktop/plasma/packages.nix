{pkgs, ...}: {
  home.packages = with pkgs; [
    bibata-cursors
    tela-icon-theme
    nordzy-icon-theme
    nordic
    libnotify
    fontconfig
    procps
    dbus
    inter
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono
    monocraft
    miracode
    kdePackages.kde-gtk-config
    kdePackages.breeze-gtk
    kdePackages.breeze
    kdePackages.qtstyleplugin-kvantum
    kdePackages.qtmultimedia
    smart-video-wallpaper
  ];

  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "kvantum";
  };

  xdg.configFile."Kvantum/kvantum.kvconfig" = {
    force = true;
    text = ''
      [General]
      theme=Nordic-Darker
    '';
  };

  xdg.configFile."Kvantum/Nordic-Darker".source = "${pkgs.nordic}/share/Kvantum/Nordic-Darker";
}
