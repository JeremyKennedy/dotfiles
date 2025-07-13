# Desktop configuration using modular structure
{
  inputs,
  outputs,
  pkgs,
  ...
}: {
  imports = [
    # Use the desktop profile which includes core + desktop modules
    ../../profiles/desktop.nix

    # Host-specific configurations
    ./filesystems.nix
    ./network.nix
    ./scripts.nix
    ./secrets.nix

    # Hardware configuration
    ./hardware-configuration.nix

    # Import home-manager's NixOS module
    inputs.home-manager.nixosModules.home-manager
  ];

  # Host-specific settings
  networking.hostName = "navi";

  # Host-specific boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Host installation version
  system.stateVersion = "23.05";
}
