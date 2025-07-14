# AdGuard Home DNS filtering service
#
# DNS Flow:
# 1. Queries for *.sole-bigeye.ts.net → Tailscale MagicDNS (if device has Tailscale)
# 2. All other queries → AdGuard Home (bee:53) → Filtered upstream DNS
# 3. Local domains (*.home.jeremyk.net) → AdGuard DNS rewrites → bee (100.74.102.74)
#
# Access Methods:
# - https://adguard.home.jeremyk.net (via Traefik + Tailscale)
# - http://bee.sole-bigeye.ts.net:3000 (direct Tailscale)
# - http://100.74.102.74:3000 (direct Tailscale IP)
# - http://192.168.1.245:3000 (LAN access if Tailscale is down)
#
# Initial setup: Create admin user via web interface
#
# Features:
# - DNS filtering and ad blocking for all network devices
# - DNSSEC support
# - DoH/DoT upstream support
# - Web interface on port 3000 (Tailscale only)
# - DNS service on port 53 (primary DNS server for LAN + Tailscale forwarding)
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    host = "0.0.0.0";
    port = 3000;
    settings = {
      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 53;

        # Upstream DNS servers
        upstream_dns = [
          "https://cloudflare-dns.com/dns-query"
          "https://dns.google/dns-query"
          "1.1.1.1"
          "1.0.0.1"
          "8.8.8.8"
          "8.8.4.4"
        ];

        # Bootstrap DNS for DoH
        bootstrap_dns = [
          "1.1.1.1"
          "8.8.8.8"
        ];

        # Enable DNSSEC
        enable_dnssec = true;

        # Cache configuration
        cache_size = 4194304; # 4MB
        cache_ttl_min = 0;
        cache_ttl_max = 86400;
        cache_optimistic = true;

        # Privacy settings
        anonymize_client_ip = false;

        # Performance settings
        ratelimit = 20;
        refuse_any = true;
      };

      # Basic filtering configuration
      filtering = {
        filtering_enabled = true;
        parental_enabled = false;
        safebrowsing_enabled = true;
        safesearch_enabled = false;

        # DNS rewrites for local domains
        rewrites = [
          {
            domain = "*.home";
            answer = "100.74.102.74";
          }
          {
            domain = "*.home.jeremyk.net";
            answer = "100.74.102.74";
          }
        ];
      };

      # OISD big blocklist - comprehensive and well-maintained
      filters = [
        {
          enabled = true;
          url = "https://big.oisd.nl";
          name = "OISD Big Blocklist";
          id = 1;
        }
      ];

      # Web interface settings
      users = []; # Configure via web UI on first run
      auth_attempts = 5;
      block_auth_min = 15;
      http_proxy = "";
      language = "en";
      theme = "auto";
    };
  };

  # Open firewall for DNS and web interface
  networking.firewall = {
    allowedTCPPorts = [53]; # DNS over TCP
    allowedUDPPorts = [53]; # DNS over UDP

    # Web interface only accessible via Tailscale
    interfaces."tailscale0".allowedTCPPorts = [3000];
  };

  # Ensure AdGuard starts after network is up
  systemd.services.adguardhome = {
    after = ["network-online.target" "tailscaled.service"];
    wants = ["network-online.target"];
  };

  # DNS Configuration for Tailscale Integration
  networking.nameservers = ["127.0.0.1"]; # Fallback (not used when Tailscale manages DNS)
  networking.resolvconf.enable = false;

  # Disable systemd-resolved to prevent conflicts
  services.resolved.enable = lib.mkForce false;

  # Let Tailscale manage /etc/resolv.conf for bee's own DNS resolution
  # This allows bee to resolve Tailscale hostnames (*.sole-bigeye.ts.net)
  # Client devices still use AdGuard directly via bee:53
  # Static resolv.conf commented out to allow Tailscale DNS management for bee
}
