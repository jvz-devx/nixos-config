{...}: {
  # herdr's in-app Settings cannot write to this read-only file; edit
  # herdr.toml here and run `herdr server reload-config` after switching.
  xdg.configFile."herdr/config.toml".source = ./herdr.toml;
}
