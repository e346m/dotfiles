{
  description = "Home Manager configuration of eiji";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    old-nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, old-nixpkgs, ... }:
      let
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        darwinPkgs = (import nixpkgs {
          system = "aarch64-darwin";
        });
        overlay-old = final: prev: {
          old = old-nixpkgs.legacyPackages.${prev.system};
        };
      in
      {
        homeConfigurations = {
          "eiji" = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              ({ config, pkgs, ...}: {
                nixpkgs.overlays = [overlay-old];
              })
              ./home.nix
              {
                home = {
                  username = "eiji";
                  homeDirectory = "/home/eiji";
                };
              }
            ];
          };

          "eijimishiro" = home-manager.lib.homeManagerConfiguration {
            pkgs = darwinPkgs;
            modules = [
              ({ config, pkgs, ...}: {
                nixpkgs.overlays = [overlay-old];
                nixpkgs.config.allowUnfree = true;
                nixpkgs.config.allowUnsupportedSystem = true;
                nixpkgs.config.allowBroken = true;
              })
              ./home.nix
              {
                home = {
                  username = "eijimishiro";
                  homeDirectory = "/Users/eijimishiro";
                };
              }
            ];
          };
        };
      };
}
