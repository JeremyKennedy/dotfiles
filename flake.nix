# https://github.com/Misterio77/nix-starter-configs/blob/main/standard/flake.nix
{
  description = "Main NixOS config file";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable"; # For bleeding-edge packages

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

  outputs = {
    self,
    nixpkgs,
    colmena,
    ...
  } @ inputs: let
    inherit (self) outputs;
    systems = ["x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    inherit (import ./modules/core/hosts.nix) hosts;
  in {
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
          just
        ];
      };
    });

    # Custom packages
    packages = {
      aarch64-linux.pi-sd-image = (nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs outputs;};
        modules = [
          inputs.agenix.nixosModules.default
          ./hosts/pi/default.nix
          {
            # Enable SD image building for this variant
            pi-sd-image.enable = true;
            # Disable disko for SD image
            disabledModules = [ ./hosts/pi/disko.nix ];
          }
        ];
      }).config.system.build.sdImage;
    };

    nixosConfigurations = {
      navi = nixpkgs.lib.nixosSystem {
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
        nixpkgs = import nixpkgs {system = "x86_64-linux";};
        specialArgs = {inherit inputs outputs;};
      };

      navi = {
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
          targetHost = hosts.bee.ip;
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
          targetHost = hosts.halo.ip;
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
          targetHost = hosts.pi.ip;
          targetUser = "root";
          buildOnTarget = false; # Build locally with emulation
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
