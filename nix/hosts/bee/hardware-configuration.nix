# Hardware configuration for bee (Beelink Mini PC placeholder)
# This file will be replaced with actual hardware config during deployment
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  # Typical modules for Beelink Mini PC (AMD Ryzen-based)
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}