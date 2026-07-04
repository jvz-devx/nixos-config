# Boot configuration - systemd-boot
# Shared boot module for all hosts
{
  config,
  lib,
  ...
}: {
  options.myConfig.system.boot.enable = lib.mkEnableOption "Boot configuration (systemd-boot)";

  config = lib.mkIf config.myConfig.system.boot.enable {
    # Bootloader
    boot.loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false; # Disable editing boot entries for security
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkDefault 3; # Use mkDefault to allow ISO module to override
    };
  };
}
