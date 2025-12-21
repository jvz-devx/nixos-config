{
  description = "NixOS configuration for ROG Strix G16";

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
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    # Custom packages
    packages.${system} = import ./pkgs pkgs;

    # Formatter for nix files
    formatter.${system} = pkgs.alejandra;

    # Overlays
    overlays = import ./overlays {inherit inputs;};

    # Reusable NixOS modules (uncomment when you have modules to export)
    # nixosModules = import ./modules/nixos;

    # Reusable home-manager modules (uncomment when you have modules to export)
    # homeManagerModules = import ./modules/home-manager;

    # NixOS configuration
    nixosConfigurations = {
      rog-strix = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          # Import chaotic modules for CachyOS kernel
          chaotic.nixosModules.default
          # Host configuration
          ./hosts/rog-strix/configuration.nix

          # Home Manager as NixOS module
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = {inherit inputs;};
              users.jens = import ./home/jens/home.nix;
              # Add plasma-manager module to home-manager
              sharedModules = [
                plasma-manager.homeModules.plasma-manager
              ];
            };
          }
        ];
      };
    };
  };
}

