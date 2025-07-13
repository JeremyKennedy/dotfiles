# Desktop services and utilities
{pkgs, ...}: {
  # Printing support
  services.printing.enable = true;

  # Network discovery and mDNS
  services.avahi = {
    enable = true;
    nssmdns4 = true; # Enable mDNS NSS plugin
    openFirewall = true; # Open UDP port 5353
  };

  # Keyring for storing credentials
  services.gnome.gnome-keyring.enable = true;

  # Container platform
  virtualisation.docker.enable = true;

  # Universal package manager
  services.flatpak.enable = true;

  # Automatic mounting of removable media
  services.udisks2.enable = true;
}
