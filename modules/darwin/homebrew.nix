{...}: {
  homebrew = {
    enable = true;

    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "none";
    };

    taps = [
      "TheBoredTeam/boring-notch"
      "pear-devs/pear"
    ];

    # GUI apps and Mac-specific utilities live in Homebrew casks.
    casks = [
      "raycast"
      "dockdoor"
      "betterdisplay"
      "shottr"
      "jordanbaird-ice"
      "stats"
      "macs-fan-control"
      "pearcleaner"
      "linearmouse"
      "latest"
      "keka"
      "hyperkey"
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
      "uv"
      "pipx"
      "rustup"
      "nvm"
    ];
  };
}
