{
  config,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      # System Tools & Utilities (unique to home-manager)
      hcloud # Hetzner Cloud CLI
      killall # kill processes by name
      nvd # nixos version diff
      xsel # command line interface to X selections

      # Monitoring & System Info (unique to home-manager)
      radeontop # AMD GPU usage monitoring utility

      # Graphics
      libva
      libva-utils
      vulkan-tools

      # Media utilities
      sound-theme-freedesktop # System sounds
      sox # Sound processing utility (play command)

      # User-specific applications
      kemai # personal productivity app
      nextcloud-client
      

      # Fun & Miscellaneous
      cowsay # configurable talking cow
      (fortune.override {withOffensive = true;}) # random adages
      lolcat # rainbow text

      # Backup & Disk Management
      gparted # partition editor
      udiskie # automount disks
      vorta

      # Disabled/Commented packages
      # corectrl # AMD GPU control and monitoring (similar to nvidia-settings)
      # libreoffice
    ];
  };
}
