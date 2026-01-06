# Gaming profile - gaming support
# Enables gaming programs and tools
{
  config,
  lib,
  ...
}: {
  options.myConfig.profiles.gaming.enable = lib.mkEnableOption "Gaming profile (Steam, Proton, GameMode)";

  config = lib.mkIf config.myConfig.profiles.gaming.enable {
    myConfig.programs.gaming = {
      enable = true;
      sunshine.enable = true;
    };
  };
}
