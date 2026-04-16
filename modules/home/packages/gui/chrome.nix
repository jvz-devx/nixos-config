{pkgs, ...}: {
  home.packages = with pkgs; [
    (google-chrome.override {
      commandLineArgs = [
        "--ozone-platform-hint=auto"
        "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
        "--disable-features=UseChromeOSDirectVideoDecoder,HardwareMediaKeyHandling,GlobalMediaControls"
        "--enable-gpu-rasterization"
        "--enable-blink-features=MiddleClickAutoscroll"
      ];
    })
  ];
}
