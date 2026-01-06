{ pkgs, ... }: {
  home.packages = with pkgs; [
    (google-chrome.override {
      commandLineArgs = [
        "--ozone-platform-hint=auto"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,CanvasOopRasterization"
        "--disable-features=UseChromeOSDirectVideoDecoder,HardwareMediaKeyHandling,GlobalMediaControls"
        "--ignore-gpu-blocklist"
        "--enable-gpu-rasterization"
        "--enable-zero-copy"
        "--enable-blink-features=MiddleClickAutoscroll"
      ];
    })
  ];
}

