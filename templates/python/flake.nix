{
  description = "A Nix-flake-based Python development environment";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
  };

  outputs = { self, nixpkgs, flake-utils  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      with pkgs;
      {
        devShells.default = mkShell {
          buildInputs = [
            python312
            poetry
            vscode-extensions.ms-pyright.pyright
            stdenv.cc.cc.lib
          ];
          LD_LIBRARY_PATH = "${stdenv.cc.cc.lib}/lib";
        };
      }
    );
}
