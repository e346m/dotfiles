{
  description = "A Nix-flake-based Node.js development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      # Configuration variables
      nodeVersion = 22; # Change this to update Node.js version (18, 20, 22, etc.)
      packageManager = "npm"; # Change this to "yarn" or "pnpm" if preferred
      
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ self.overlays.default ];
        };
      });
    in
    {
      overlays.default = final: prev: {
        nodejs = final."nodejs_${toString nodeVersion}";
        
        # Rebuild package managers with the specified Node.js version
        nodePackages = prev.nodePackages.override {
          nodejs = final."nodejs_${toString nodeVersion}";
        };
        
        # Select package manager based on configuration
        selectedPackageManager = 
          if packageManager == "npm" then final.nodePackages.npm
          else if packageManager == "yarn" then final.nodePackages.yarn
          else if packageManager == "pnpm" then final.nodePackages.pnpm
          else final.nodePackages.npm; # fallback to npm
      };

      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Node.js runtime
            nodejs
            
            # Package manager (built with the same Node.js version)
            selectedPackageManager
          ];

          shellHook = ''
            echo "🚀 Node.js ${pkgs.nodejs.version} development environment"
            echo "📦 Package manager: ${packageManager}"
            echo ""
            echo "Get started:"
            echo "  ${packageManager} init          # Initialize package.json"
            echo "  ${packageManager} install <pkg> # Install dependencies"
            echo "  ${packageManager} run <script>  # Run scripts"
            echo "  node index.js                   # Run your app"
            echo ""
          '';

        };
      });
    };
} 