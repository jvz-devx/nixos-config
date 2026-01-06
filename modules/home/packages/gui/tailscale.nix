{pkgs, ...}: {
  home.packages = with pkgs; [
    ktailctl
  ];

  # Autostart applications
  xdg.configFile."autostart/ktailctl.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Tailscale
    Exec=ktailctl --minimized
    Icon=ktailctl
    Comment=Tailscale VPN Manager
    Categories=Network;
    X-GNOME-Autostart-enabled=true
  '';
}
