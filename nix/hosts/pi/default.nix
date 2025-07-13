# Raspberry Pi 4 configuration for pi
{ config, pkgs, lib, ... }: {
  imports = [
    ../common
    ./disko.nix
  ];
  
  networking.hostName = "pi";
  system.stateVersion = "24.11";
  nixpkgs.hostPlatform = "aarch64-linux";

  # Raspberry Pi specific boot configuration
  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };

  # Performance settings for ARM/Pi4
  zramSwap.enable = true;
  
  # Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
}