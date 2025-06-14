# https://github.com/Misterio77/nix-starter-configs/blob/main/standard/flake.nix
{
  description = "Main NixOS config file";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland = {
      url = "github:hyprwm/Hyprland";
      # build with your own instance of nixpkgs
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    nixpkgs-master,
    home-manager,
    hyprland
  } @ inputs: let
    inherit (self) outputs;
    # Supported systems for your flake packages, shell, etc.
    systems = [
      "x86_64-linux"
    ];
    # This is a function that generates an attribute by calling a function you
    # pass to it, with each system as an argument
    forAllSystems = nixpkgs.lib.genAttrs systems;
    # Your secrets, like API keys, etc
    secrets = builtins.fromJSON (builtins.readFile "${self}/secrets.json");
  in {
    # Your custom packages
    # Accessible through 'nix build', 'nix shell', etc
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});

    # Formatter for your nix files, available through 'nix fmt'
    # Other options beside 'alejandra' include 'nixpkgs-fmt'
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Your custom packages and modifications, exported as overlays
    overlays = import ./overlays {inherit inputs;};

    # # Reusable nixos modules you might want to export
    # # These are usually stuff you would upstream into nixpkgs
    # nixosModules = import ./modules/nixos;

    nixosConfigurations = {
      JeremyDesktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs secrets;};
        modules = [
          hyprland.nixosModules.default
          {programs.hyprland.enable = true;}
          ./nixos/configuration.nix
        ];
      };
    };
  };
}
