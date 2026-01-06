# Development profile - development tools
# Enables development programs and tools
{
  config,
  lib,
  ...
}: {
  options.myConfig.profiles.development.enable = lib.mkEnableOption "Development profile (Docker, languages, CLI tools)";

  config = lib.mkIf config.myConfig.profiles.development.enable {
    myConfig.programs.development.enable = true;
  };
}
