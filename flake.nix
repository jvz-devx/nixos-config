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

    # TODO: Uncomment for CachyOS kernel (gaming-optimized)
    # chaotic = {
    #   url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
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
            };
          }
        ];
      };
    };
  };
}

