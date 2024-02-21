{
  description = "A simple NixOS flake";

  inputs = {
    # NixOS official package source, using the nixos-23.11 branch here
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = 
		{ self, nixpkgs, nixpkgs-unstable }: 
		let
      system = "x86_64-linux";
			overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          inherit system;
          config.allowUnfree = true;
        };
      };
		in {
	    nixosConfigurations = {
				JeremyDesktop = nixpkgs.lib.nixosSystem {
					inherit system;
					modules = [
						({ config, pkgs, ... }: {nixpkgs.overlays = [ overlay-unstable ]; })
						./configuration.nix
					];
				};
			};
		};
}
