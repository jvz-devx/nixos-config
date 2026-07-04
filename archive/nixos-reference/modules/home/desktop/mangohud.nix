{pkgs, ...}: {
  programs.mangohud = {
    enable = true;
    enableSessionWide = false;
    settings = {
      legacy_layout = false;
      horizontal = false;
      hud_compact = true;
      round_corners = 0;
      background_alpha = "0.0";
      background_color = "000000";
      font_size = 24;
      text_color = "FFFFFF";
      position = "top-left";
      table_columns = 3;

      # GPU Stats
      gpu_stats = true;
      gpu_text = "GPU";
      gpu_load_change = true;
      gpu_load_value = "50,90";
      gpu_load_color = "FFFFFF,FFAA7F,CC0000";
      gpu_color = "2E9762";
      vram = true;
      vram_color = "AD64C1";
      gpu_core_clock = true;
      gpu_mem_clock = true;
      gpu_temp = true;
      gpu_mem_temp = true;
      gpu_junction_temp = true;
      gpu_fan = true;
      gpu_power = true;
      gpu_power_limit = true;
      gpu_efficiency = true;
      gpu_voltage = true;
      throttling_status = true;
      gpu_name = true;

      # CPU Stats
      cpu_stats = true;
      cpu_text = "CPU";
      cpu_load_change = true;
      cpu_load_value = "50,90";
      cpu_load_color = "FFFFFF,FFAA7F,CC0000";
      cpu_color = "2E97CB";
      cpu_mhz = true;
      cpu_temp = true;
      cpu_power = true;

      # System
      io_read = true;
      io_write = true;
      io_color = "A491D3";
      ram = true;
      ram_color = "C26693";
      battery = true;
      battery_color = "00FF00";
      battery_watt = true;

      # FPS / Performance
      fps = true;
      fps_color = "B22222,FDFD09,39F900";
      fps_value = "30,60";
      frame_timing = true;
      frametime_color = "00FF00";
      fps_limit = 117;
      fps_limit_method = "late";
      toggle_fps_limit = "Shift_L+F1";

      # Engine / Driver info
      vulkan_driver = true;
      engine_version = true;
      engine_color = "EB5B5B";
      wine = true;

      # Others
      resolution = true;
    };
  };
}
