# Workstation profile - composite profile for full-featured workstations
# Combines desktop, gaming, and development profiles
{
  config,
  lib,
  ...
}: {
  options.myConfig.profiles.workstation.enable = lib.mkEnableOption "Workstation profile (desktop + gaming + development)";

  config = lib.mkIf config.myConfig.profiles.workstation.enable {
    myConfig.profiles.desktop.enable = true;
    myConfig.profiles.gaming.enable = true;
    myConfig.profiles.development.enable = true;
  };
}
