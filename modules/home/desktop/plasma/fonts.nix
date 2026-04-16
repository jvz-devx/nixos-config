{pkgs, ...}: let
  userFont = "GlobalUserFont";
  toggle-font = pkgs.writeShellScriptBin "toggle-font" ''
        CONF_DIR="$HOME/.config/fontconfig/conf.d"
        CONF_FILE="$CONF_DIR/99-user-font.conf"
        mkdir -p "$CONF_DIR"

        if grep -q "Monocraft Nerd Font" "$CONF_FILE" 2>/dev/null; then
          TARGET_FONT="Miracode"
        else
          TARGET_FONT="Monocraft Nerd Font"
        fi

        rm -f "$CONF_FILE"
        cat > "$CONF_FILE" <<EOF
    <?xml version="1.0"?>
    <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
    <fontconfig>
      <alias>
        <family>${userFont}</family>
        <prefer>
          <family>$TARGET_FONT</family>
        </prefer>
      </alias>
    </fontconfig>
    EOF

        for key in font fixed menuFont toolBarFont activeFont; do
          ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key "$key" "$TARGET_FONT,10,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"
        done

        ${pkgs.kdePackages.kconfig}/bin/kwriteconfig6 --file kdeglobals --group General --key smallestReadableFont "$TARGET_FONT,8,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"

        ${pkgs.fontconfig}/bin/fc-cache -f
        ${pkgs.libnotify}/bin/notify-send "Font Switcher" "Switched to $TARGET_FONT.\nPlease log out and back in for full effect." -i font
  '';
in {
  home.packages = [toggle-font];

  xdg.configFile."fontconfig/conf.d/99-user-font.conf" = {
    force = true;
    text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <alias>
          <family>${userFont}</family>
          <prefer>
            <family>Monocraft Nerd Font</family>
          </prefer>
        </alias>
      </fontconfig>
    '';
  };

  programs.plasma.fonts = {
    general = {
      family = userFont;
      pointSize = 10;
    };
    fixedWidth = {
      family = userFont;
      pointSize = 10;
    };
    small = {
      family = userFont;
      pointSize = 8;
    };
    toolbar = {
      family = userFont;
      pointSize = 10;
    };
    menu = {
      family = userFont;
      pointSize = 10;
    };
    windowTitle = {
      family = userFont;
      pointSize = 10;
    };
  };

  programs.plasma.hotkeys.commands."toggle-font" = {
    name = "Toggle Font (Monocraft/Miracode)";
    key = "Ctrl+Alt+PageUp";
    command = "${toggle-font}/bin/toggle-font";
  };
}
