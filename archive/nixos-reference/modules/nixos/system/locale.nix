# Locale configuration - timezone, keyboard, i18n
# Shared locale module (configured for Netherlands)
{
  config,
  lib,
  ...
}: {
  options.myConfig.system.locale.enable = lib.mkEnableOption "System locale configuration (timezone, keyboard, i18n)";

  config = lib.mkIf config.myConfig.system.locale.enable {
    # Timezone
    time.timeZone = "Europe/Amsterdam";

    # Locale
    i18n = {
      defaultLocale = "en_GB.UTF-8";
      extraLocaleSettings = {
        LC_TIME = "nl_NL.UTF-8";
        LC_MONETARY = "nl_NL.UTF-8";
      };
    };

    # Console keymap (Dutch)
    console.keyMap = "nl";

    # X11/Wayland keyboard layout - Dutch Mac layout
    services.xserver.xkb = {
      layout = "nl";
      variant = "mac";
    };

    # Networking
    networking.networkmanager.enable = true;

    # Default editor
    programs.nano.enable = true;
    environment.variables.EDITOR = "nano";
    environment.variables.VISUAL = "nano";
  };
}
