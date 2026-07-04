{pkgs, ...}: {
  home.packages = with pkgs; [
    vesktop # Discord with Vencord mod
    teams-for-linux
    parsec-bin # Remote desktop/game streaming
  ];

  # Add custom font support to Vesktop via Vencord's QuickCSS
  xdg.configFile."vesktop/settings/quickCss.css".text = ''
    :root {
      --font-primary: "GlobalUserFont", "gg sans", "Noto Sans", sans-serif;
      --font-display: "GlobalUserFont", "gg sans", "Noto Sans", sans-serif;
      --font-headline: "GlobalUserFont", "ABC Ginto Normal", "gg sans", sans-serif;
      --font-code: "GlobalUserFont", "Source Code Pro", monospace;
    }
  '';
}
