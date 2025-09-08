{
  description = "my minimal flake";
  inputs = {
    # Use the darwin-specific branch of nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-24.11-darwin";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    # Match home-manager version with nixpkgs
    home-manager.url = "github:nix-community/home-manager/release-24.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Correct URL format for nix-darwin with matching version
    darwin.url = "github:lnl7/nix-darwin/nix-darwin-24.11";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = {
    self,
    nixpkgs,
    darwin,
    home-manager,
    ...
  } @ inputs: {
    darwinConfigurations = {
      Samis-MacBook-Air = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        modules = [
          home-manager.darwinModules.home-manager
          ./config.nix
        ];
      };
      Gmtk-MacBook-Pro = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        pkgs = import nixpkgs { system = "aarch64-darwin"; };
        modules = [
          home-manager.darwinModules.home-manager
          ./config.nix
          ({ lib, ... }: { networking.hostName = lib.mkForce "Gmtk-MacBook-Pro"; })
        ];
      };
    };
  };
}
