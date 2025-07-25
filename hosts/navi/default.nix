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
    ./services.nix
    ./secrets.nix

    # Hardware configuration
    ./hardware-configuration.nix

    # Services for this host
    ../../modules/services/monitoring/netdata.nix

    # System modules
    ../../modules/system/debug-tools.nix

    # Import home-manager's NixOS module
    inputs.home-manager.nixosModules.home-manager
  ];

  # Host-specific boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 20;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Host installation version
  system.stateVersion = "23.05";
}
