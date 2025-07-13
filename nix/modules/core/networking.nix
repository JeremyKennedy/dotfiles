# Basic networking configuration for all hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable NetworkManager for easier network management
  networking.networkmanager.enable = true;

  # Custom DNS configuration
  networking.networkmanager.dns = "none";
  networking.nameservers = [
    "100.100.100.100" # Tailscale DNS
    "192.168.1.245" # bee (AdGuard Home)
  ];
  networking.search = ["sole-bigeye.ts.net"];

  # Enable DHCP for now until static IPs are confirmed working
  networking.useDHCP = lib.mkDefault true;
  networking.dhcpcd.enable = lib.mkDefault true;

  # Tailscale for all hosts
  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Basic network optimizations
  boot.kernel.sysctl = {
    # Increase Linux autotuning TCP buffer limits
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";

    # Increase the maximum number of incoming connections
    "net.core.somaxconn" = 4096;

    # Enable TCP Fast Open
    "net.ipv4.tcp_fastopen" = 3;
  };
}
