# Basic networking configuration for all hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Use systemd-networkd for declarative network management
  networking.useNetworkd = true;
  networking.useDHCP = false; # Explicit per-interface DHCP

  # Let systemd-resolved manage resolv.conf
  networking.resolvconf.enable = false;

  # Configure systemd-networkd
  systemd.network = {
    enable = true;
    networks."10-ethernet" = {
      matchConfig.Name = "en*";
      networkConfig = {
        DHCP = "ipv4";
        IPv6AcceptRA = true;
        DNS = [ "100.74.102.74" ]; # bee DNS server (Tailscale IP)
        Domains = [ "~home" "~home.jeremyk.net" ]; # Search domains
      };
      dhcpV4Config = {
        UseDNS = false; # Ignore DHCP-provided DNS
      };
    };
  };

  # Use systemd-resolved for DNS
  services.resolved = {
    enable = true;
    dnssec = "false"; # May conflict with bee's AdGuard
    domains = [ "~." ];
    fallbackDns = [ "100.74.102.74" ]; # bee fallback (Tailscale IP)
  };

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
