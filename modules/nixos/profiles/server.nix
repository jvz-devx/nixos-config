# Server profile - headless server configuration
# Enables essential server features: locale, boot, disk, maintenance, tailscale, development tools
# Does NOT enable desktop/gaming modules (headless server)
{ config, lib, ... }: {
  options.myConfig.profiles.server.enable = lib.mkEnableOption "Server profile (headless: locale, boot, disk, maintenance, tailscale, development tools)";

  config = lib.mkIf config.myConfig.profiles.server.enable {
    # System configuration
    myConfig.system.locale.enable = true;
    myConfig.system.boot.enable = true;
    myConfig.system.disk.enable = true;
    
    # Services
    myConfig.services.maintenance.enable = true;
    myConfig.services.tailscale.enable = true;
    
    # Development tools (includes Docker, CLI tools, monitoring, network tools)
    myConfig.programs.development.enable = true;
  };
}

