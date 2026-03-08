{pkgs, ...}: let
  userFont = "GlobalUserFont";
in {
  programs.wezterm = {
    enable = true;
    extraConfig = ''
      local wezterm = require 'wezterm'
      local config = wezterm.config_builder()

      -- Nord color scheme to match Nordic KDE theme
      config.color_scheme = 'nord'

      -- Font (uses the global user font alias)
      config.font = wezterm.font('${userFont}')
      config.font_size = 11

      -- Window appearance - match KDE Nordic theme
      config.window_background_opacity = 0.85
      config.kde_window_background_blur = true
      config.window_decorations = "TITLE|RESIZE"
      config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }

      -- Tab bar
      config.use_fancy_tab_bar = true
      config.hide_tab_bar_if_only_one_tab = false
      config.tab_bar_at_bottom = false

      -- Performance
      config.max_fps = 60
      config.animation_fps = 1
      config.front_end = "WebGpu"

      -- Behaviour
      config.window_close_confirmation = 'NeverPrompt'
      config.scrollback_lines = 10000
      config.enable_scroll_bar = false

      -- Cursor
      config.default_cursor_style = 'BlinkingBlock'
      config.cursor_blink_rate = 500

      return config
    '';
  };
}
