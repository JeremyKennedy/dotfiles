# https://github.com/Misterio77/nix-starter-configs/blob/main/standard/flake.nix
{
  description = "Main NixOS config file";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";  # For bleeding-edge packages

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, colmena, ... }@inputs: let
    inherit (self) outputs;
    systems = ["x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # Development shell for homelab management
    devShells = forAllSystems (system: {
      default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          # Only include tools not in system/home-manager config
          inputs.colmena.packages.${system}.colmena
          nixos-anywhere
          inputs.disko.packages.${system}.disko
        ];
        
        shellHook = ''
          echo "🔧 NixOS Homelab Dev Environment"
          echo "📦 Additional tools: colmena, nixos-anywhere, disko"
          echo "🎯 Hosts: JeremyDesktop, bee, halo, pi"
          echo ""
          echo "System tools already available: alejandra, agenix, git, nix-tree, nix-diff"
        '';
      };
    });

    nixosConfigurations = {
      JeremyDesktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.hyprland.nixosModules.default
          {programs.hyprland.enable = true;}
          inputs.agenix.nixosModules.default
          ./hosts/navi/default.nix
        ];
      };
      
      bee = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          ./hosts/bee/default.nix
        ];
      };
      
      halo = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          ./hosts/halo/default.nix
        ];
      };
      
      pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          ./hosts/pi/default.nix
        ];
      };
    };
    
    # Colmena deployment configuration - expose as colmenaHive
    colmenaHive = inputs.colmena.lib.makeHive {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        specialArgs = { inherit inputs outputs; };
      };
      
      JeremyDesktop = {
        deployment = {
          targetHost = "localhost";
          targetUser = "root";
          buildOnTarget = false;
        };
        imports = [
          inputs.hyprland.nixosModules.default
          {programs.hyprland.enable = true;}
          inputs.agenix.nixosModules.default
          ./hosts/navi/default.nix
        ];
      };
      
      bee = {
        deployment = {
          targetHost = "192.168.1.245";
          targetUser = "root";
          buildOnTarget = false;
        };
        imports = [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          ./hosts/bee/default.nix
        ];
      };
      
      halo = {
        deployment = {
          targetHost = "46.62.144.212";
          targetUser = "root";
          buildOnTarget = false;
        };
        imports = [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          ./hosts/halo/default.nix
        ];
      };
      
      pi = {
        deployment = {
          targetHost = "192.168.1.230";
          targetUser = "root";
          buildOnTarget = false;  # Build ARM on desktop
        };
        nixpkgs.system = "aarch64-linux";
        imports = [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          ./hosts/pi/default.nix
        ];
      };
    };
  };
}
