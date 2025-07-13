# Raspberry Pi 4 configuration for pi
{ config, pkgs, lib, ... }: {
  imports = [
    ../common
    ./disko.nix
  ];
  
  networking.hostName = "pi";
  system.stateVersion = "24.11";
  nixpkgs.hostPlatform = "aarch64-linux";

  # Raspberry Pi specific boot configuration - override common systemd-boot
  boot.loader = {
    systemd-boot.enable = lib.mkForce false;
    efi.canTouchEfiVariables = lib.mkForce false;
    grub.enable = false;
    generic-extlinux-compatible.enable = true;
  };
}