{
  description = "Home Manager configuration of eiji";

  inputs = {
    # Specify the source of Home Manager and Nixpkgs.
    nixpkgs.url = "github:nixos/nixpkgs/3016b4b15d13f3089db8a41ef937b13a9e33a8df";
    old-nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";
    roc.url = "github:roc-lang/roc";
  };

  outputs =
    {
      nixpkgs,
      utils,
      home-manager,
      old-nixpkgs,
      unstable,
      roc,
      ...
    }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      darwinPkgs = (import nixpkgs { system = "aarch64-darwin"; });
      overlay-old = final: prev: {
        old = old-nixpkgs.legacyPackages.${prev.system};
      };
      overlay-unstable = final: prev: {
        unstable = unstable.legacyPackages.${prev.system};
      };
      overlay-custom = final: prev: {
        claude-code = prev.callPackage (./. + "/pkgs/claude-code.nix") { };
        gemini-cli = unstable.legacyPackages.${prev.system}.gemini-cli;
        roc = roc.packages.${prev.system}.cli;
        roc-ls = roc.packages.${prev.system}.lang-server;
      };

      allowUnfree = (
        { config, pkgs, ... }:
        {
          nixpkgs.overlays = [
            overlay-old
            overlay-unstable
            overlay-custom
          ];
          nixpkgs.config.allowUnfree = true;
          nixpkgs.config.allowUnsupportedSystem = true;
          nixpkgs.config.allowBroken = true;
        }
      );
    in
    {
      homeConfigurations = {
        "eiji" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            allowUnfree
            ./modules/common.nix
            ./modules/desktop-linux.nix
          ];
        };

        "eijimishiro" = home-manager.lib.homeManagerConfiguration {
          pkgs = darwinPkgs;
          modules = [
            allowUnfree
            ./modules/common.nix
            ./modules/mbp-m2.nix
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

        node = {
          path = ./templates/node;
          description = "Node development environment";
        };
      };
    };
}
