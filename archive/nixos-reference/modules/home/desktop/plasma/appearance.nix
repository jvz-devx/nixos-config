{osConfig, ...}: let
  gpuMode = osConfig.myConfig.hardware.nvidia.mode or "desktop";
  isIntegrated = gpuMode == "integrated";
in {
  programs.plasma.workspace = {
    clickItemTo = "select";
    lookAndFeel = "Nordic-darker";
    cursor = {
      theme = "Bibata-Modern-Classic";
      size = 24;
    };
    iconTheme = "Tela-black-dark";
    wallpaper =
      if isIntegrated
      then ../../../../assets/wallpaper/wallpaper-static.png
      else ../../../../assets/wallpaper/deyuin6-c7ad1dee-e0ae-423c-8e1a-bc4addf550e0.gif;
  };

  programs.plasma.configFile = {
    kdeglobals.General.widgetStyle = "kvantum";
    plasmarc."PlasmaTheme"."blurEnabled" = true;
    plasmarc."PlasmaTheme"."transparencyEnabled" = true;
    plasmarc."PlasmaTheme"."backgroundContrastEnabled" = false;
    plasmarc."Theme"."name" = "Nordic-darker";
    plasmarc.Wallpapers.usersWallpapers = "${../../../../assets/wallpaper/deyuin6-c7ad1dee-e0ae-423c-8e1a-bc4addf550e0.gif}";
  };
}
