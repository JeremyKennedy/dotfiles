# Automatic hardware detection and optimization
{ lib, config, modulesPath, ... }: {
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  
  # Auto-detect kernel modules based on platform
  boot.initrd.availableKernelModules = lib.mkDefault 
    (if config.nixpkgs.hostPlatform == "aarch64-linux" 
     then [ "usbhid" "usb_storage" ] 
     else [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ]);
  
  # KVM support based on CPU type
  boot.kernelModules = lib.mkDefault 
    (if builtins.elem config.nixpkgs.hostPlatform [ "x86_64-linux" "i686-linux" ]
     then [ (if config.hardware.cpu.intel.updateMicrocode then "kvm-intel" else "kvm-amd") ]
     else [ ]);
  
  # Universal performance improvements
  boot.kernel.sysctl = {
    "vm.swappiness" = lib.mkDefault 10;  # Reduce swap usage
    "vm.vfs_cache_pressure" = lib.mkDefault 50;  # Better file cache
  };
  
  # Modern hardware support
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  
  # CPU microcode updates (auto-detects Intel/AMD)
  hardware.cpu.intel.updateMicrocode = 
    lib.mkDefault config.hardware.enableRedistributableFirmware;
  hardware.cpu.amd.updateMicrocode = 
    lib.mkDefault config.hardware.enableRedistributableFirmware;
    
  # Platform detection
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}