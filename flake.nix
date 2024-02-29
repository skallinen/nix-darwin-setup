{
  description = "my minimal flake";
  inputs = {
    # Where we get most of our software. Giant mono repo with recipes
    # called derivations that say how to build software.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05"; # nixos-22.11
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    # Controls system level software and settings including fonts
    darwin.url = "github:lnl7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = {
    self,
    nixpkgs,
    darwin,
    home-manager,
    ...
  } @ inputs: {
    darwinConfigurations.Samis-MacBook-Air = darwin.lib.darwinSystem {
      system = "aarch64-darwin";
      pkgs = import nixpkgs {system = "aarch64-darwin";};
      modules = [
        home-manager.darwinModules.home-manager
        ./config.nix
      ];
    };
  };
}
