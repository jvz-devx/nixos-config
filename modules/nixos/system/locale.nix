# Locale configuration - timezone, keyboard, i18n
# Shared locale module (configured for Netherlands)
{ ... }: {
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
}


