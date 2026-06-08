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
    ];

    # Mac-specific or ecosystem-sensitive CLI tools stay in Brew.
    brews = [
      "colima"
      "docker"
      "docker-compose"
      "azure-cli"
      "cliclick"
      "cmake"
      "fastfetch"
      "ffmpeg"
      "kubeconform"
      "uv"
      "pipx"
      "rustup"
      "nvm"
    ];
  };
}
