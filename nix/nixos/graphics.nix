{
  config,
  pkgs,
  ...
}: {
  # Use AMD GPU for X/Wayland
  services.xserver.videoDrivers = ["amdgpu"];

  # Required for AMD GPU firmware blobs
  hardware.enableRedistributableFirmware = true;

  # Early KMS to load AMD driver during initrd
  boot.initrd.kernelModules = ["amdgpu"];

  # Add kernel module for regular boot too (needed for CoreCtrl)
  # boot.kernelModules = ["amdgpu"];

  # Configure DRI for CoreCtrl
  # services.xserver.deviceSection = ''
  #   Option "DRI" "3"
  # '';

  # OpenGL and Vulkan (gaming support)
  hardware.opengl = {
    enable = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      mesa # Base Mesa drivers
      amdvlk # AMD Vulkan driver
      vaapiVdpau # VDPAU bridge for video acceleration compatibility
    ];
    # 32-bit packages for Steam and other games
    extraPackages32 = with pkgs; [
      driversi686Linux.amdvlk # 32-bit Vulkan support for Steam games
    ];
  };
}
