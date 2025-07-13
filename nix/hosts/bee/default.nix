# Beelink Mini PC configuration for bee
{ config, pkgs, lib, ... }: {
  imports = [
    ../common
    ./disko.nix
    ./hardware-configuration.nix
  ];
  
  networking.hostName = "bee";
  system.stateVersion = "24.11";

  # Boot configuration for UEFI systems
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Additional packages for server management
  environment.systemPackages = with pkgs; [
    ethtool
  ];

  # Performance
  zramSwap.enable = true;

  # Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}