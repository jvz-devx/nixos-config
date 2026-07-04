{
  inputs,
  lib,
  osConfig,
  ...
}: let
  hyprlandCfg = osConfig.myConfig.desktop.hyprland or {};
  cfgEnabled = hyprlandCfg.enable or false;
  terminalCommand = hyprlandCfg.terminal or "foot";
  caelestiaDots = inputs.caelestia-dots;
in {
  config = lib.mkIf cfgEnabled {
    xdg.configFile = {
      "foot/foot.ini" = {
        source = "${caelestiaDots}/foot/foot.ini";
      };

      "fish/config.fish" = {
        source = "${caelestiaDots}/fish/config.fish";
      };

      "fish/functions/fish_greeting.fish" = {
        source = "${caelestiaDots}/fish/functions/fish_greeting.fish";
      };

      "starship.toml" = {
        source = "${caelestiaDots}/starship.toml";
      };

      "Thunar/uca.xml" = {
        source = "${caelestiaDots}/thunar/uca.xml";
      };

      "xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml" = {
        source = "${caelestiaDots}/thunar/thunar-volman.xml";
      };

      "kitty/kitty.conf" = {
        force = true;
        text = ''
          # Managed by Home Manager.

          font_family JetBrainsMono Nerd Font
          bold_font auto
          italic_font auto
          bold_italic_font auto
          font_size 12.5
          disable_ligatures never

          cursor_shape beam
          cursor_blink_interval 0.5
          cursor_trail 1
          enable_audio_bell no
          visual_bell_duration 0.0
          window_alert_on_bell no

          foreground #e0def4
          background #191724
          selection_foreground #e0def4
          selection_background #31748f
          cursor #ebbcba
          cursor_text_color #191724
          url_color #9ccfd8
          active_border_color #9ccfd8
          inactive_border_color #6e6a86
          bell_border_color #f6c177
          color0 #191724
          color1 #eb6f92
          color2 #9ccfd8
          color3 #f6c177
          color4 #31748f
          color5 #c4a7e7
          color6 #ebbcba
          color7 #e0def4
          color8 #6e6a86
          color9 #eb6f92
          color10 #9ccfd8
          color11 #f6c177
          color12 #31748f
          color13 #c4a7e7
          color14 #ebbcba
          color15 #e0def4

          background_opacity 0.86
          dynamic_background_opacity yes
          window_padding_width 10
          single_window_margin_width 0
          placement_strategy center
          hide_window_decorations yes

          tab_bar_edge bottom
          tab_bar_style powerline
          tab_powerline_style slanted
          tab_title_template "{fmt.fg._9ccfd8}{index}{fmt.fg.default}: {title}"
          active_tab_font_style bold
          inactive_tab_font_style normal

          scrollback_lines 20000
          wheel_scroll_multiplier 3.0
          touch_scroll_multiplier 3.0
          copy_on_select clipboard
          strip_trailing_spaces smart
          open_url_with default
          url_style curly

          allow_remote_control yes
          shell_integration enabled
          confirm_os_window_close 0
          update_check_interval 0

          map ctrl+shift+enter new_window_with_cwd
          map ctrl+shift+t new_tab_with_cwd
          map ctrl+shift+w close_tab
          map ctrl+shift+h previous_tab
          map ctrl+shift+l next_tab
          map ctrl+shift+c copy_to_clipboard
          map ctrl+shift+v paste_from_clipboard
          map ctrl+shift+equal change_font_size all +1.0
          map ctrl+shift+minus change_font_size all -1.0
          map ctrl+shift+backspace change_font_size all 0
        '';
      };

      "fuzzel/fuzzel.ini" = {
        force = true;
        text = ''
          [main]
          font=JetBrainsMono Nerd Font:size=13
          width=54
          lines=14
          horizontal-pad=18
          vertical-pad=14
          inner-pad=10
          terminal=${terminalCommand}
          prompt="> "
          layer=overlay

          [colors]
          background=191724ee
          text=e0def4ff
          prompt=9ccfd8ff
          input=e0def4ff
          match=f6c177ff
          selection=31748fee
          selection-text=e0def4ff
          border=9ccfd8aa

          [border]
          width=1
          radius=12
        '';
      };
    };
  };
}
