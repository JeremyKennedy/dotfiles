# AdGuard Home DNS filtering service
#
# Web Interface Access:
# - https://adguard.home.jeremyk.net (via Traefik + Tailscale)
# - http://adguard.home:3000 (via CoreDNS + Tailscale)
# - http://bee.sole-bigeye.ts.net:3000 (direct Tailscale)
# - http://100.74.102.74:3000 (direct Tailscale IP)
# - http://192.168.1.245:3000 (LAN access if Tailscale is down)
#
# DNS Server Access:
# - DNS queries: 192.168.1.245:53 (primary DNS for network)
# - DNS queries: bee.sole-bigeye.ts.net:53 (via Tailscale)
# - DNS queries: 100.74.102.74:53 (Tailscale IP)
#
# Initial setup: Create admin user via web interface
#
# IMPORTANT: DNS rewrites are configured declaratively under settings.filtering.rewrites
# With mutableSettings = false, the configuration is fully managed by Nix.
#
# Features:
# - DNS filtering and ad blocking
# - DNSSEC support
# - DoH/DoT upstream support
# - Web interface on port 3000 (Tailscale only)
# - DNS service on port 53 (primary DNS server)
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

  # Set this server as the system DNS resolver
  networking.nameservers = ["127.0.0.1"];
  networking.resolvconf.enable = false;

  # Ensure /etc/resolv.conf points to local DNS
  environment.etc."resolv.conf".text = ''
    nameserver 127.0.0.1
    options edns0
  '';
}
