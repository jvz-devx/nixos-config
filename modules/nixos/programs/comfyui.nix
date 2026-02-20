# ComfyUI - node-based UI for Stable Diffusion (Docker-based)
# Uses a pre-built Docker image with NVIDIA GPU support instead of compiling from source.
# The container does NOT autostart — use comfyui-start / comfyui-stop shell aliases.
{
  config,
  lib,
  ...
}: let
  cfg = config.myConfig.programs.comfyui;
in {
  options.myConfig.programs.comfyui = {
    enable = lib.mkEnableOption "ComfyUI (node-based Stable Diffusion UI via Docker)";

    port = lib.mkOption {
      type = lib.types.port;
      default = 8188;
      description = "Port for the ComfyUI web interface.";
    };

    dataDir = lib.mkOption {
      type = lib.types.str;
      default = "/home/jens/comfyui";
      description = "Directory for models, outputs, and custom nodes.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for the ComfyUI port.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Use Docker as the OCI backend (development module already enables Docker)
    virtualisation.oci-containers.backend = "docker";

    virtualisation.oci-containers.containers.comfyui = {
      image = "yanwk/comfyui-boot:cu126-megapak";
      autoStart = false;
      ports = ["127.0.0.1:${toString cfg.port}:8188"];
      volumes = [
        "${cfg.dataDir}/models:/root/ComfyUI/models"
        "${cfg.dataDir}/output:/root/ComfyUI/output"
        "${cfg.dataDir}/input:/root/ComfyUI/input"
        "${cfg.dataDir}/custom_nodes:/root/ComfyUI/custom_nodes"
      ];
      extraOptions = ["--device=nvidia.com/gpu=all"];
    };

    # Open firewall if requested
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [cfg.port];

    # Shell aliases for on-demand start/stop
    environment.shellAliases = {
      comfyui-start = "sudo systemctl start docker-comfyui";
      comfyui-stop = "sudo systemctl stop docker-comfyui";
      comfyui-logs = "sudo journalctl -u docker-comfyui -f";
    };
  };
}
