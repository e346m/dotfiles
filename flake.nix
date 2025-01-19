{
  description = "Home Manager configuration of eiji";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    old-nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, utils, home-manager, old-nixpkgs, ... }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      darwinPkgs = (import nixpkgs { system = "aarch64-darwin"; });
      overlay-old = final: prev: {
        old = old-nixpkgs.legacyPackages.${prev.system};
      };

      overlay = final: prev: {
        vimPlugins = prev.vimPlugins // {
          copilot-lua = prev.vimPlugins.copilot-lua.overrideAttrs (old: {
            postInstall = ''
              sed -i "s! copilot_node_command = \"node\"! copilot_node_command = \"${prev.nodejs}/bin/node\"!g" $out/lua/copilot/config.lua
            '';
          });
        };
      };

      allowUnfree = ({ config, pkgs, ... }: {
        nixpkgs.overlays = [ overlay-old overlay ];
        nixpkgs.config.allowUnfree = true;
        nixpkgs.config.allowUnsupportedSystem = true;
      });
    in {
      homeConfigurations = {
        "eiji" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            allowUnfree
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
            allowUnfree
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

        templates = {
          go = {
            path = ./templates/go;
            description = "Go development environment";
          };

          python = {
            path = ./templates/python;
            description = "Python development environment";
          };
        };
    };
}
