# LocalSend - cross-platform file sharing
{
  config,
  lib,
  ...
}: {
  options.myConfig.programs.localsend.enable = lib.mkEnableOption "LocalSend (cross-platform file sharing)";

  config = lib.mkIf config.myConfig.programs.localsend.enable {
    programs.localsend = {
      enable = true;
      openFirewall = true; # Opens port 53317 (TCP/UDP)
    };
  };
}
