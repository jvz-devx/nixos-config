{
  config,
  lib,
  pkgs,
  ...
}: let
  userFont = "GlobalUserFont";
in {
  # Konsole General Settings
  programs.plasma.configFile."konsolerc" = {
    "Desktop Entry"."DefaultProfile" = "Default.profile";
    "Favorite Profiles"."Favorites" = "Default.profile";
    "UiSettings"."ColorScheme" = "NordicDarker";
  };

  # SSH Manager Configuration (Encrypted via SOPS)
  sops.secrets.proxmox_host = {};

  sops.templates."konsolesshconfig" = {
    path = "${config.home.homeDirectory}/.config/konsolesshconfig";
    content = ''
      [Global plugin config]
      manageProfile=false

      [SSH Config][Proxmox]
      hostname=${config.sops.placeholder.proxmox_host}
      identifier=Proxmox
      importedFromSshConfig=false
      port=22
      profileName=Do not Change
      sshkey=
      useSshConfig=true
      username=

      [SSH Config][github.com]
      hostname=github.com
      identifier=github.com
      importedFromSshConfig=true
      port=
      profileName=
      sshkey=~/.ssh/id_ed25519
      useSshConfig=true
      username=git
    '';
  };

  # Konsole Profile
  xdg.dataFile."konsole/Default.profile".text = ''
    [Appearance]
    ColorScheme=Nordic
    Font=${userFont},10,-1,5,50,0,0,0,0,0
    Blur=true
    Opacity=0.85

    [General]
    Name=Default
    Parent=FALLBACK

    [Scrolling]
    HistoryMode=2
    HistorySize=10000

    [Terminal Features]
    BlinkingCursorEnabled=true
  '';

  # Nordic Konsole Color Scheme
  xdg.dataFile."konsole/Nordic.colorscheme".text = ''
    [Background]
    Color=46,52,64

    [BackgroundIntense]
    Color=59,66,82

    [Color0]
    Color=59,66,82

    [Color0Intense]
    Color=76,86,106

    [Color1]
    Color=191,97,106

    [Color1Intense]
    Color=191,97,106

    [Color2]
    Color=163,190,140

    [Color2Intense]
    Color=163,190,140

    [Color3]
    Color=235,203,139

    [Color3Intense]
    Color=235,203,139

    [Color4]
    Color=129,161,193

    [Color4Intense]
    Color=129,161,193

    [Color5]
    Color=180,142,173

    [Color5Intense]
    Color=180,142,173

    [Color6]
    Color=136,192,208

    [Color6Intense]
    Color=143,188,187

    [Color7]
    Color=229,233,240

    [Color7Intense]
    Color=236,239,244

    [Foreground]
    Color=216,222,233

    [ForegroundIntense]
    Color=236,239,244

    [General]
    Description=Nordic
    Opacity=0.85
    Wallpaper=
  '';
}
