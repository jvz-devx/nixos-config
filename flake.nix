{
  description = "Multi-host NixOS configuration";

  inputs = {
    # Nixpkgs - using unstable for latest Plasma 6, kernel 6.12+, drivers
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Keep a stable reference for packages that need it
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

    # Home Manager - following nixpkgs
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Plasma Manager - for declarative KDE configuration
    plasma-manager = {
      url = "github:nix-community/plasma-manager";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    # Chaotic-nyx for CachyOS kernel (gaming-optimized)
    # DEPRECATED: Project was archived on 2025-12-08.
    # Future migration path: https://github.com/xddxdd/nix-cachyos-kernel
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Claude Code (native binary, auto-updated from npm)
    claude-code = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Codex CLI (OpenAI Codex command-line tool)
    codex-cli = {
      url = "github:sadjow/codex-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # nix-ai-tools (includes Factory AI's droid CLI)
    nix-ai-tools = {
      url = "github:numtide/nix-ai-tools";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # sops-nix for secrets management
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS-WSL
    nixos-wsl = {
      url = "github:nix-community/NixOS-WSL/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Rust overlay - for pinning specific Rust toolchain versions
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Pin nixpkgs for Stremio to avoid qtwebengine build issues
    nixpkgs-stremio.url = "github:nixos/nixpkgs/5135c59491985879812717f4c9fea69604e7f26f";

    # Latest nixpkgs for packages that need a newer snapshot than nixos-unstable.
    # We currently rely on this for opencode/Codex auth support and Vesktop.
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    # Temporary direct upstream pin kept only in the lock file history.
    # The active opencode fix now comes from nixpkgs-master's packaged derivation.
    opencode-upstream.url = "github:sst/opencode/v1.4.3";
    opencode-upstream.inputs.nixpkgs.follows = "nixpkgs-master";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    plasma-manager,
    chaotic,
    claude-code,
    codex-cli,
    nix-ai-tools,
    sops-nix,
    nixos-wsl,
    nixpkgs-stremio,
    nixpkgs-master,
    ...
  } @ inputs: let
    # Systems you want to support
    supportedSystems = ["x86_64-linux" "aarch64-linux"];

    # Helper function to generate attributes for all systems
    forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

    # Nixpkgs instantiated for each system (with unfree allowed)
    pkgsFor = system:
      import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };
  in rec {
    # Custom packages - available for all supported systems
    packages =
      forAllSystems (system: import ./pkgs (pkgsFor system))
      // {
        x86_64-linux =
          (forAllSystems (system: import ./pkgs (pkgsFor system))).x86_64-linux
          // {
            # ISO images for all hosts
            server-01-iso = nixosConfigurations.server-01-iso.config.system.build.isoImage;
            pc-02-iso = nixosConfigurations.pc-02-iso.config.system.build.isoImage;
            rog-strix-iso = nixosConfigurations.rog-strix-iso.config.system.build.isoImage;
          };
      };

    # Formatter for nix files - available for all supported systems
    formatter = forAllSystems (system: (pkgsFor system).alejandra);

    # Overlays
    overlays = import ./overlays {inherit inputs;};

    # NixOS configurations - add new hosts here
    nixosConfigurations = {
      # ═══════════════════════════════════════════════════════════════
      # ROG Strix G16 laptop - Jens
      # Intel CPU + NVIDIA GPU with ASUS-specific features
      # ═══════════════════════════════════════════════════════════════
      rog-strix = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # Chaotic-nyx module (provides CachyOS kernel and gaming packages)
          chaotic.nixosModules.default
          # sops-nix for secrets management
          sops-nix.nixosModules.sops
          # All NixOS modules (options & profiles)
          ./modules/nixos/default.nix
          # Host configuration
          ./hosts/rog-strix/configuration.nix
          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {inherit inputs;};
              users.jens = import ./home/jens.nix;
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };

      # ═══════════════════════════════════════════════════════════════
      # PC-02 Desktop - Lisa
      # AMD CPU + NVIDIA GPU desktop
      # ═══════════════════════════════════════════════════════════════
      pc-02 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # sops-nix for secrets management
          sops-nix.nixosModules.sops
          # All NixOS modules (options & profiles)
          ./modules/nixos/default.nix
          # Host configuration
          ./hosts/pc-02/configuration.nix
          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {inherit inputs;};
              users.jens = import ./home/jens.nix;
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };

      # ═══════════════════════════════════════════════════════════════
      # Server-01 - Headless Server
      # General purpose server with Docker, Tailscale, and essential tools
      # ═══════════════════════════════════════════════════════════════
      server-01 = let
        pkgs = import inputs.nixpkgs-stable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      in
        nixpkgs.lib.nixosSystem {
          inherit pkgs;
          system = "x86_64-linux";
          specialArgs = {inherit inputs;};
          modules = [
            # sops-nix for secrets management
            sops-nix.nixosModules.sops
            # All NixOS modules (options & profiles)
            ./modules/nixos/default.nix
            # Host configuration
            ./hosts/server-01/configuration.nix
            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {inherit inputs;};
                users.admin = import ./home/server.nix;
                sharedModules = [
                  sops-nix.homeManagerModules.sops
                ];
              };
            }
          ];
        };

      # ═══════════════════════════════════════════════════════════════
      # ISO Images - Bootable installation media
      # ═══════════════════════════════════════════════════════════════

      # Server-01 ISO - bootable installation image
      server-01-iso = let
        pkgs = import inputs.nixpkgs-stable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      in
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit inputs pkgs;};
          modules = [
            # ISO installer modules
            "${pkgs.path}/nixos/modules/installer/cd-dvd/iso-image.nix"
            # ISO boot settings (UEFI + BIOS, Proxmox/OVMF-friendly)
            {
              isoImage.makeEfiBootable = true;
              isoImage.makeUsbBootable = true;
              isoImage.volumeID = "NIXOS_SERVER_01";

              # iso-image.nix provides its own bootloader.
              boot.loader.systemd-boot.enable = nixpkgs.lib.mkForce false;
              boot.loader.grub.enable = nixpkgs.lib.mkForce false;
              boot.loader.efi.canTouchEfiVariables = nixpkgs.lib.mkForce false;

              # Ensure the initrd can see the ISO device in common VM setups.
              boot.initrd.availableKernelModules = [
                "virtio_pci"
                "virtio_blk"
                "virtio_scsi"
                "sr_mod"
                "sd_mod"
                "ahci"
                "ata_piix"
                "xhci_pci"
                "usbhid"
                "usb_storage"
                "uas"
              ];
            }
            # sops-nix for secrets management
            sops-nix.nixosModules.sops
            # All NixOS modules (options & profiles)
            ./modules/nixos/default.nix
            # Host configuration
            ./hosts/server-01/configuration.nix
            # Enable ISO autologin
            {myConfig.system.iso.autologin = true;}
          ];
        };

      # PC-02 ISO - Lisa's desktop installation image (with NVIDIA)
      pc-02-iso = let
        pkgs = pkgsFor "x86_64-linux";
      in
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit inputs;};
          modules = [
            # ISO installer modules
            "${pkgs.path}/nixos/modules/installer/cd-dvd/iso-image.nix"
            # sops-nix for secrets management
            sops-nix.nixosModules.sops
            # All NixOS modules (options & profiles)
            ./modules/nixos/default.nix
            # Host configuration
            ./hosts/pc-02/configuration.nix
            # Enable ISO autologin
            {myConfig.system.iso.autologin = true;}
            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {inherit inputs;};
                users.jens = import ./home/jens.nix;
                sharedModules = [
                  plasma-manager.homeModules.plasma-manager
                  sops-nix.homeManagerModules.sops
                ];
              };
            }
          ];
        };

      # ROG Strix ISO - Jens' laptop installation image (with NVIDIA + CachyOS)
      rog-strix-iso = let
        pkgs = pkgsFor "x86_64-linux";
      in
        nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = {inherit inputs;};
          modules = [
            # ISO installer modules
            "${pkgs.path}/nixos/modules/installer/cd-dvd/iso-image.nix"
            # Chaotic-nyx module (provides CachyOS kernel and gaming packages)
            chaotic.nixosModules.default
            # sops-nix for secrets management
            sops-nix.nixosModules.sops
            # All NixOS modules (options & profiles)
            ./modules/nixos/default.nix
            # Host configuration
            ./hosts/rog-strix/configuration.nix
            # Enable ISO autologin
            {myConfig.system.iso.autologin = true;}
            # Home Manager
            home-manager.nixosModules.home-manager
            {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                backupFileExtension = "backup";
                extraSpecialArgs = {inherit inputs;};
                users.jens = import ./home/jens.nix;
                sharedModules = [
                  plasma-manager.homeModules.plasma-manager
                  sops-nix.homeManagerModules.sops
                ];
              };
            }
          ];
        };

      # ═══════════════════════════════════════════════════════════════
      # WSL - NixOS on Windows Subsystem for Linux
      # ═══════════════════════════════════════════════════════════════
      wsl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # NixOS-WSL module
          nixos-wsl.nixosModules.default
          # sops-nix for secrets management
          sops-nix.nixosModules.sops
          # All NixOS modules (options & profiles)
          ./modules/nixos/default.nix
          # Host configuration
          ./hosts/wsl/configuration.nix
          # Home Manager
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = {inherit inputs;};
              users.jens = import ./home/wsl.nix;
              sharedModules = [
                sops-nix.homeManagerModules.sops
              ];
            };
          }
        ];
      };
    };
  };
}
