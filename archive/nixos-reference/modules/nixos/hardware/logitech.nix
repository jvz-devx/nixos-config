# Logitech hardware support and mouse tweaks
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.myConfig.hardware.logitech;
in {
  options.myConfig.hardware.logitech = {
    enable = lib.mkEnableOption "Logitech hardware support (ratbagd, piper, and scroll fixes)";
  };

  config = lib.mkIf cfg.enable {
    # ratbagd for mouse configuration (DPI, buttons)
    services.ratbagd.enable = true;

    # Piper is the GUI for ratbagd
    environment.systemPackages = [pkgs.piper];

    # Fix for G502 hypersensitive scrolling in games (High-Res Scroll)
    # This disables high-resolution scrolling events which many games misinterpret
    # We use both a udev rule for libinput attributes and a libinput quirk
    services.udev.extraRules = ''
      # Disable high-resolution scrolling for Logitech G502 to fix game sensitivity
      ATTRS{name}=="Logitech G502*", ENV{LIBINPUT_ATTR_SCROLL_PIXELS_PER_STEP}="0"
    '';

    # Libinput quirk to explicitly disable High-Res scroll events
    environment.etc."libinput/local-overrides.quirks".text = ''
      [Logitech G502 Discrete Scroll]
      MatchName=Logitech G502*
      AttrEventCode=-REL_WHEEL_HI_RES;-REL_HWHEEL_HI_RES;
    '';
  };
}
