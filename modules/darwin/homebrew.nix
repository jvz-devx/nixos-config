{...}: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "check";
    };

    taps = [
      "TheBoredTeam/boring-notch"
      "aannoo/hcom"
      "can1357/tap"
      "dmtrKovalenko/fff"
      "pear-devs/pear"
    ];

    # GUI apps and Mac-specific utilities live in Homebrew casks.
    casks = [
      "raycast"
      "rectangle"
      "hammerspoon"
      "alt-tab"
      "moonlight"
      "dockdoor"
      "betterdisplay"
      "shottr"
      "stats"
      "macs-fan-control"
      "pearcleaner"
      "linearmouse"
      "localsend"
      "displaylink"
      "latest"
      "keka"
      "hyperkey"
      "bitwarden"
      "TheBoredTeam/boring-notch/boring-notch"
      "pear-devs/pear/pear-desktop"
      "ghostty"
      "visual-studio-code"
      "blender"
      "codexbar"
      # "vibeproxy"
      # "claude-code"
      "libreoffice"
      "gstreamer-runtime"
      "wine-stable"
      "porting-kit"
      {
        name = "rar";
        postinstall = "/usr/bin/xattr -dr com.apple.quarantine /opt/homebrew/Caskroom/rar";
      }
    ];

    # Mac-specific or ecosystem-sensitive CLI tools stay in Brew.
    brews = [
      "aannoo/hcom/hcom"
      "colima"
      "docker"
      "docker-compose"
      "azure-cli"
      "btop"
      "cloudflare-wrangler"
      "cliclick"
      "cmake"
      "fastfetch"
      "ffmpeg"
      "can1357/tap/omp"
      "dmtrKovalenko/fff/fff-mcp"
      "fontconfig"
      "kubeconform"
      "libtiff"
      "little-cms2"
      "macmon"
      "webp"
      "uv"
      "pipx"
      "rustup"
      "nvm"
      "openjdk@25"
      "nzbget"
    ];
  };
}
