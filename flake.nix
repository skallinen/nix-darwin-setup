{
  description = "Hybrid Mac and NixOS Flake";

  inputs = {
    # NixOS Official (Covers both Mac and Linux packages)
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11"; 
    
    # Home Manager
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Darwin Support
    darwin.url = "github:lnl7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, home-manager, ... }: 
  let
    # Helper to clean up configuration definitions
    mkMac = host: module: darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import nixpkgs { system = "aarch64-darwin"; config.allowUnfree = true; };
      modules = [
        home-manager.darwinModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
        }
        module
      ];
    };
  in {
    # --- macOS Configurations ---
    darwinConfigurations = {
      "Samis-MacBook-Air" = mkMac "Samis-MacBook-Air" ./darwin-configuration.nix;
      
      "Gmtk-MacBook-Pro" = mkMac "Gmtk-MacBook-Pro" ({ lib, ... }: {
        imports = [ ./darwin-configuration.nix ];
        networking.hostName = lib.mkForce "Gmtk-MacBook-Pro";
      });
    };

    # --- NixOS VM Configuration ---
    nixosConfigurations."nixos-vm" = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./vm-configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.samikallinen = { 
            imports = [ ./shared-home.nix ]; 
          };
        }
      ];
    };
  };
}
