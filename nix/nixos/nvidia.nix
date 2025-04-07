{
  config,
  pkgs,
  ...
}: {
  # Load nvidia driver for Xorg and Wayland
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is needed most of the time
    modesetting.enable = true;

    # Enable power management (do not disable this unless you have a reason to).
    # Likely to cause problems on laptops and with screen tearing if disabled.
    powerManagement.enable = true;

    # Use the NVidia open source kernel module (which isn't "nouveau").
    # Support is limited to the Turing and later architectures. Full list of
    # supported GPUs is at:
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus
    # Only available from driver 515.43.04+
    open = false;

    # Enable the Nvidia settings menu,
    # accessible via `nvidia-settings`.
    nvidiaSettings = true;

    # Use the specific beta driver version 570.123.06
    package = config.boot.kernelPackages.nvidiaPackages.stable.overrideAttrs {
      src = pkgs.fetchurl {
        url = "https://developer.download.nvidia.com/assets/gameworks/downloads/secure/Vulkan_Beta_Drivers/NVIDIA-Linux-x86_64-570.123.06.run?__token__=exp=1742479030~hmac=f6f740b0059f2cfb0d4bd6229a4d8bb51943e619f252d4f43f4bce91da7121ff";
        sha256 = "sha256-3FwT5B51P+ktNM2UZw6nQDuS7EMpbfV0qkuRtohhNnk=";
      };
    };

    # Comment out or remove the previous package line
    # package = config.boot.kernelPackages.nvidiaPackages.beta;

    # force old nvidia
    #package = (config.boot.kernelPackages.nvidiaPackages.stable.overrideAttrs {
    #  src = pkgs.fetchurl {
    #    url = "https://download.nvidia.com/XFree86/Linux-x86_64/525.125.06/NVIDIA-Linux-x86_64-525.125.06.run";
    #    sha256 = "17av8nvxzn5af3x6y8vy5g6zbwg21s7sq5vpa1xc6cx8yj4mc9xm";
    #  };
    #});
    #package = (config.boot.kernelPackages.nvidiaPackages.stable.overrideAttrs {
    #  src = pkgs.fetchurl {
    #    url = "https://download.nvidia.com/XFree86/Linux-x86_64/535.104.05/NVIDIA-Linux-x86_64-535.104.05.run";
    #    sha256 = "1jgdrczy70jlg9ybi1z8mm9q5vg78rf66dknfppbww573nfn179g";
    #  };
    #});
  };
}
