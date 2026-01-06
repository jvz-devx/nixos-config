{
  pkgs,
  inputs,
  lib,
  ...
}: let
  stremio-pkgs = import inputs.nixpkgs-stremio {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  # Wrap Stremio to unset QT_PLUGIN_PATH to avoid library mismatch with Plasma 6 environment
  # and ensure it can find mpv and ffmpeg for playback (using pinned versions for compatibility)
  stremio-wrapped =
    pkgs.runCommand "stremio" {
      nativeBuildInputs = [pkgs.makeWrapper];
    } ''
      mkdir -p $out/share
      ln -s ${stremio-pkgs.stremio}/share/* $out/share/
      makeWrapper ${stremio-pkgs.stremio}/bin/stremio $out/bin/stremio \
        --unset QT_PLUGIN_PATH \
        --unset QT_QPA_PLATFORMTHEME \
        --unset QT_STYLE_OVERRIDE \
        --prefix PATH : ${lib.makeBinPath [stremio-pkgs.mpv stremio-pkgs.ffmpeg pkgs.vlc pkgs.yt-dlp]} \
        --set LD_LIBRARY_PATH ${lib.makeLibraryPath [pkgs.libva]}
    '';
in {
  home.packages = [stremio-wrapped];
}
