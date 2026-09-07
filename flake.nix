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
    mymate.url = "github:upsidr/mymate";
    whisrs.url = "github:y0sif/whisrs";
    herdr.url = "github:herdrdev/herdr/v0.8.2";
    hunk.url = "github:modem-dev/hunk";
  };

  outputs =
    {
      nixpkgs,
      utils,
      home-manager,
      old-nixpkgs,
      unstable,
      roc,
      mymate,
      whisrs,
      herdr,
      hunk,
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
        agentic-nvim = prev.callPackage (./. + "/pkgs/agentic-nvim.nix") { };
        antigravity = prev.callPackage (./. + "/pkgs/antigravity.nix") { };
        guard-hook = prev.callPackage (./. + "/pkgs/guard-hook.nix") { };
        googleworkspace-cli = prev.callPackage (./. + "/pkgs/googleworkspace-cli.nix") { };
        claude-latency = prev.callPackage (./. + "/pkgs/claude-latency.nix") { };
        tsm = prev.callPackage (./. + "/pkgs/tsm.nix") { };
        llama-diffusion = prev.callPackage (./. + "/pkgs/llama-diffusion.nix") { };
        cursor-cli = (import unstable { inherit (prev) system; config.allowUnfree = true; }).cursor-cli;
        code-cursor = (import unstable { inherit (prev) system; config.allowUnfree = true; }).code-cursor;
        ghostty = unstable.legacyPackages.${prev.system}.ghostty;
        yazi = unstable.legacyPackages.${prev.system}.yazi;
        neovim = unstable.legacyPackages.${prev.system}.neovim;
        neovim-unwrapped = unstable.legacyPackages.${prev.system}.neovim-unwrapped;
        vimPlugins = unstable.legacyPackages.${prev.system}.vimPlugins;
        mcp-grafana = unstable.legacyPackages.${prev.system}.mcp-grafana;
        roc = roc.packages.${prev.system}.cli;
        roc-ls = roc.packages.${prev.system}.lang-server;
        mymate = mymate.packages.${prev.system}.default;
        whisrs = whisrs.packages.${prev.system}.default;
        herdr = herdr.packages.${prev.system}.default;
        hunk = hunk.packages.${prev.system}.default;
        super = (import unstable { inherit (prev) system; config.allowUnfree = true; }).super;
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
            ./modules/otel-collector.nix
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
