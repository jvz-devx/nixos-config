{
  description = "Multi-host NixOS configuration";

  inputs = {
    # Nixpkgs - using unstable for latest Plasma 6, kernel 6.12+, drivers
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Keep a stable reference for packages that need it
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

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
    chaotic = {
      url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
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
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    plasma-manager,
    chaotic,
    codex-cli,
    nix-ai-tools,
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
    packages = forAllSystems (system: import ./pkgs (pkgsFor system)) // {
      x86_64-linux = (forAllSystems (system: import ./pkgs (pkgsFor system))).x86_64-linux // {
        isoImage = nixosConfigurations.server-01-iso.config.system.build.isoImage;
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
              extraSpecialArgs = {inherit inputs;};
              users.jens = import ./home/jens.nix;
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
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
              extraSpecialArgs = {inherit inputs;};
              users.lisa = import ./home/lisa.nix;
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
              ];
            };
          }
        ];
      };

      # ═══════════════════════════════════════════════════════════════
      # Server-01 - Headless Server
      # General purpose server with Docker, Tailscale, and essential tools
      # ═══════════════════════════════════════════════════════════════
      server-01 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # All NixOS modules (options & profiles)
          ./modules/nixos/default.nix
          # Host configuration
          ./hosts/server-01/configuration.nix
        ];
      };

      # Server-01 ISO - bootable installation image
      server-01-iso = let
        pkgs = pkgsFor "x86_64-linux";
      in nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {inherit inputs;};
        modules = [
          # ISO installer modules - import the ISO image module
          "${pkgs.path}/nixos/modules/installer/cd-dvd/iso-image.nix"
          # All NixOS modules (options & profiles)
          ./modules/nixos/default.nix
          # Host configuration
          ./hosts/server-01/configuration.nix
        ];
      };
    };
  };
}
