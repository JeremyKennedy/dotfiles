{
  config,
  pkgs,
  ...
}: {
  home = {
    packages = with pkgs; [
      # System Tools & Utilities (unique to home-manager)
      killall # kill processes by name
      xsel # command line interface to X selections
      nvd # nixos version diff
      hcloud # Hetzner Cloud CLI

      # Monitoring & System Info (unique to home-manager)
      radeontop # AMD GPU usage monitoring utility
      # corectrl # AMD GPU control and monitoring (similar to nvidia-settings)

      # Graphics
      libva
      libva-utils
      vulkan-tools

      # Media utilities
      sox # Sound processing utility (play command)
      sound-theme-freedesktop # System sounds

      # User-specific applications
      nextcloud-client
      kemai # personal productivity app
      # libreoffice

      # Fun & Miscellaneous
      cowsay # configurable talking cow
      (fortune.override {withOffensive = true;}) # random adages
      lolcat # rainbow text

      # Backup & Disk Management
      vorta
      gparted # partition editor
      udiskie # automount disks
    ];
  };
}
