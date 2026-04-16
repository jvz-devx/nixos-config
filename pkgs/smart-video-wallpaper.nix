{
  lib,
  fetchFromGitHub,
  mkKdeDerivation,
  qtbase,
  qtdeclarative,
  qtmultimedia,
  qtsvg,
  kcoreaddons,
  kpackage,
  kwindowsystem,
  libplasma,
  ki18n,
  kcmutils,
}:
mkKdeDerivation {
  pname = "smart-video-wallpaper-reborn";
  version = "2.8.1";

  src = fetchFromGitHub {
    owner = "luisbocanegra";
    repo = "plasma-smart-video-wallpaper-reborn";
    rev = "v2.8.1";
    hash = "sha256-SpSKERzm4tKo5WvqNYiq/TfwSJY+oQWNQ93ENAA06Yc=";
  };

  extraNativeBuildInputs = [
    qtbase
  ];

  extraBuildInputs = [
    qtbase
    qtdeclarative
    qtmultimedia
    qtsvg
    kcoreaddons
    kpackage
    kwindowsystem
    libplasma
    ki18n
    kcmutils
  ];

  extraCmakeFlags = [
    "-DQt6_DIR=${qtbase}/lib/cmake/Qt6"
  ];

  dontWrapQtApps = true;

  meta = {
    description = "Smart Video Wallpaper Reborn for KDE Plasma";
    homepage = "https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
  };
}
