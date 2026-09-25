{
  lib,
  pkgs,
  ...
}: let
  # Private fork of sw33tLie/macshot (github.com/jvz-devx/macshot) carrying
  # sw33tLie/macshot#349 (sequential, cursor-display-first multi-display
  # capture) and a commit that disables upstream Sparkle updates. Bump this rev
  # after rebasing the fork onto a newer upstream. Signing, Screen Recording
  # and update steps: docs/macbook-pro.md, "macshot (private fork)".
  macshotRev = "043d5d182ad6df5188fd32065bf17d250c964d00";

  macshotForkInstall = pkgs.writeShellApplication {
    name = "macshot-fork-install";
    runtimeInputs = [pkgs.git pkgs.gh];
    text = ''
      rev="''${1:-${macshotRev}}"
      src="''${XDG_CACHE_HOME:-$HOME/.cache}/macshot-fork"
      state="''${XDG_STATE_HOME:-$HOME/.local/state}/macshot-fork"
      app=/Applications/macshot.app

      if [ ! -d "$src/.git" ]; then
        git clone --quiet https://github.com/jvz-devx/macshot.git "$src"
      fi
      git -C "$src" fetch --quiet --tags origin
      git -C "$src" -c advice.detachedHead=false checkout --quiet --force "$rev"
      version="$(git -C "$src" describe --tags --abbrev=0 2>/dev/null || echo v0.0.0)"
      version="''${version#v}"

      echo "Building macshot $version ($rev)..."
      /usr/bin/xcodebuild -quiet \
        -project "$src/macshot.xcodeproj" \
        -scheme macshot \
        -configuration Release \
        -derivedDataPath "$src/build" \
        CODE_SIGN_IDENTITY=- \
        CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
        MARKETING_VERSION="$version" \
        build

      # Re-sign with the self-signed login-keychain identity so the Screen
      # Recording grant pins the certificate instead of each build's cdhash.
      # Without that identity the ad-hoc build is installed as is.
      built="$src/build/Build/Products/Release/macshot.app"
      identity="Jens Local Code Signing"
      if /usr/bin/security find-certificate -c "$identity" >/dev/null 2>&1; then
        find "$built/Contents" -depth ! -type l \
          \( -name '*.xpc' -o -name '*.app' -o -name '*.framework' -o -name '*.dylib' \
          -o -path '*/Sparkle.framework/Versions/*/Autoupdate' \) -print0 \
          | while IFS= read -r -d "" item; do
            /usr/bin/codesign --force --sign "$identity" \
              --preserve-metadata=identifier,entitlements,flags "$item" 2>/dev/null
          done
        /usr/bin/codesign --force --sign "$identity" \
          --preserve-metadata=identifier,entitlements,flags "$built" 2>/dev/null
        /usr/bin/codesign --verify --deep --strict "$built"
      else
        echo "warning: '$identity' not in keychain; installing ad-hoc signed build" >&2
      fi

      was_running=0
      if /usr/bin/pgrep -xq macshot; then
        was_running=1
        /usr/bin/osascript -e 'tell application id "com.sw33tlie.macshot.macshot" to quit' || true
        for _ in {1..20}; do
          /usr/bin/pgrep -xq macshot || break
          /bin/sleep 0.25
        done
      fi

      rm -rf "$app"
      /usr/bin/ditto "$built" "$app"
      mkdir -p "$state"
      printf '%s\n' "$rev" > "$state/rev"
      echo "Installed macshot $version ($rev) to $app"

      if [ "$was_running" = 1 ] || [ "''${MACSHOT_LAUNCH:-1}" = 1 ]; then
        /usr/bin/open -g "$app"
      fi
    '';
  };
in {
  home.packages = [macshotForkInstall];

  # Rebuild only when the pinned rev changes or the app is missing. A failed
  # build must not abort the rest of activation.
  home.activation.installMacshotFork = lib.hm.dag.entryAfter ["writeBoundary"] ''
    macshotState="''${XDG_STATE_HOME:-$HOME/.local/state}/macshot-fork/rev"
    if [ ! -d /Applications/macshot.app ] \
      || [ "$(cat "$macshotState" 2>/dev/null)" != "${macshotRev}" ]; then
      run ${macshotForkInstall}/bin/macshot-fork-install \
        || echo "warning: macshot fork install failed; rerun macshot-fork-install" >&2
    fi
  '';
}
