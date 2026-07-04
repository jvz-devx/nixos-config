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
      "latest"
      "keka"
      "hyperkey"
      "bitwarden"
      "TheBoredTeam/boring-notch/boring-notch"
      "pear-devs/pear/pear-desktop"
      "ghostty"
      "visual-studio-code"
      "tableplus"
      "codexbar"
      "libreoffice"
      "gstreamer-runtime"
      "wine-stable"
      "porting-kit"
    ];

    # Mac-specific or ecosystem-sensitive CLI tools stay in Brew.
    brews = [
      {
        name = "colima";
        start_service = true;
      }
      "docker"
      "docker-compose"
      "azure-cli"
      "cloudflare-wrangler"
      "cliclick"
      "cmake"
      "fastfetch"
      "ffmpeg"
      "can1357/tap/omp"
      "dmtrKovalenko/fff/fff-mcp"
      "fontconfig"
      "kubeconform"
      "little-cms2"
      "uv"
      "pipx"
      "rustup"
      "nvm"
    ];
  };
}
