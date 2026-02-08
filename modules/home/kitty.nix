# Kitty terminal emulator configuration
{pkgs, ...}: {
  programs.kitty = {
    enable = true;

    # Font
    font = {
      name = "GlobalUserFont";
      size = 11;
    };

    # Shell integration (prompt jumping, CWD reporting, command notifications)
    shellIntegration = {
      enableZshIntegration = true;
      mode = "no-rc";
    };

    settings = {
      # Window appearance
      window_padding_width = 8;
      background_opacity = "0.92";
      background_blur = 20;
      confirm_os_window_close = 0;
      hide_window_decorations = false;
      remember_window_size = true;
      initial_window_width = "120c";
      initial_window_height = "35c";
      placement_strategy = "center";
      draw_minimal_borders = true;

      # Tab bar - rounded pill-shaped tabs on darker toolbar background
      tab_bar_style = "powerline";
      tab_powerline_style = "round";
      tab_title_template = " {bell_symbol}{activity_symbol}{index}: {title} ";
      active_tab_title_template = " {bell_symbol}{activity_symbol}{index}: {fmt.bold}{title}{fmt.nobold} ";
      tab_activity_symbol = "* ";
      active_tab_font_style = "bold";
      inactive_tab_font_style = "normal";
      tab_bar_edge = "top";
      tab_bar_min_tabs = 1;
      tab_bar_margin_width = "4.0";
      tab_bar_margin_height = "4.0 0.0";
      tab_bar_background = "#181825";
      active_tab_foreground = "#1e1e2e";
      active_tab_background = "#89b4fa";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#313244";

      # Cursor
      cursor_shape = "beam";
      cursor_beam_thickness = "1.5";
      cursor_blink_interval = "0.5";
      cursor_trail = 3;
      cursor_trail_decay = "0.1 0.4";
      cursor_trail_start_threshold = 2;

      # Scrollbar
      scrollbar = "hovered";
      scrollbar_interactive = true;
      scrollbar_jump_on_click = true;
      scrollbar_handle_color = "#585b70";
      scrollbar_track_color = "#313244";
      scrollbar_hover_width = 4;
      scrollbar_radius = 4;
      scrollbar_gap = 2;
      scrollbar_handle_opacity = "0.8";
      scrollbar_track_opacity = "0.3";
      scrollbar_track_hover_opacity = "0.5";

      # Scrollback
      scrollback_lines = 50000;
      wheel_scroll_multiplier = 3;
      touch_scroll_multiplier = 3;

      # Bell
      enable_audio_bell = false;
      visual_bell_duration = "0.1";

      # URLs
      url_style = "curly";
      detect_urls = true;
      open_url_with = "default";
      show_hyperlink_targets = true;

      # Functional improvements
      strip_trailing_spaces = "smart";
      select_by_word_characters = "@-./_~?&=%+#";
      clipboard_control = "write-clipboard write-primary read-clipboard-ask read-primary-ask";
      notify_on_cmd_finish = "unfocused 10.0 notify";
      sync_to_monitor = true;
      input_delay = 2;
      repaint_delay = 6;
      undercurl_style = "thin-sparse";

      # Catppuccin Mocha color scheme
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";
      url_color = "#f5e0dc";
      cursor = "#f5e0dc";
      cursor_text_color = "#1e1e2e";

      # Black
      color0 = "#45475a";
      color8 = "#585b70";
      # Red
      color1 = "#f38ba8";
      color9 = "#f38ba8";
      # Green
      color2 = "#a6e3a1";
      color10 = "#a6e3a1";
      # Yellow
      color3 = "#f9e2af";
      color11 = "#f9e2af";
      # Blue
      color4 = "#89b4fa";
      color12 = "#89b4fa";
      # Magenta
      color5 = "#f5c2e7";
      color13 = "#f5c2e7";
      # Cyan
      color6 = "#94e2d5";
      color14 = "#94e2d5";
      # White
      color7 = "#bac2de";
      color15 = "#a6adc8";
    };

    keybindings = {
      # Scroll
      "shift+up" = "scroll_line_up";
      "shift+down" = "scroll_line_down";
      "shift+page_up" = "scroll_page_up";
      "shift+page_down" = "scroll_page_down";
      "shift+home" = "scroll_home";
      "shift+end" = "scroll_end";

      # Tabs
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+w" = "close_tab";
      "ctrl+shift+right" = "next_tab";
      "ctrl+shift+left" = "previous_tab";
      "ctrl+shift+." = "move_tab_forward";
      "ctrl+shift+," = "move_tab_backward";

      # Tab numbers (browser-style)
      "alt+1" = "goto_tab 1";
      "alt+2" = "goto_tab 2";
      "alt+3" = "goto_tab 3";
      "alt+4" = "goto_tab 4";
      "alt+5" = "goto_tab 5";
      "alt+6" = "goto_tab 6";
      "alt+7" = "goto_tab 7";
      "alt+8" = "goto_tab 8";
      "alt+9" = "goto_tab 9";

      # Windows/splits
      "ctrl+shift+enter" = "new_window";
      "ctrl+shift+]" = "next_window";
      "ctrl+shift+[" = "previous_window";
      "ctrl+shift+q" = "close_window";

      # Splits
      "ctrl+alt+\\" = "launch --location=vsplit";
      "ctrl+alt+minus" = "launch --location=hsplit";

      # Layout/window management
      "ctrl+shift+l" = "next_layout";
      "ctrl+shift+f" = "toggle_layout stack";
      "ctrl+shift+r" = "start_resizing_window";
      "ctrl+shift+h" = "neighboring_window left";
      "ctrl+shift+j" = "neighboring_window down";
      "ctrl+shift+k" = "neighboring_window up";

      # Scrollback & config
      "ctrl+shift+g" = "show_scrollback";
      "ctrl+shift+f5" = "load_config_file";

      # Font size
      "ctrl+shift+equal" = "change_font_size all +1.0";
      "ctrl+shift+minus" = "change_font_size all -1.0";
      "ctrl+shift+0" = "change_font_size all 0";
    };

    extraConfig = ''
      # Right-click paste from clipboard
      mouse_map right press ungrabbed paste_from_clipboard
      # Middle-click paste from primary selection
      mouse_map middle release ungrabbed paste_from_selection
      # Ctrl+click to open URLs
      mouse_map ctrl+left click ungrabbed mouse_handle_click link
    '';
  };
}
