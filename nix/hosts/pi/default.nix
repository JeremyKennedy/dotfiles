# Raspberry Pi 4 configuration for pi
{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    # Use server profile
    ../../profiles/server.nix
    # Host-specific (when available)
    # ./disko.nix
    # ./hardware-configuration.nix
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
