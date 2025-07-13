# AdGuard Home DNS filtering service
#
# Access: http://bee.sole-bigeye.ts.net:3000
# Initial setup: Create admin user via web interface
#
# Features:
# - DNS filtering and ad blocking
# - DNSSEC support
# - DoH/DoT upstream support
# - Web interface on port 3000 (Tailscale only)
# - DNS service on port 5353 (used by CoreDNS)
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.adguardhome = {
    enable = true;
    mutableSettings = true;
    host = "0.0.0.0";
    port = 3000;
    settings = {
      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 5353;

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
      };

      # Default blocklists
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
          name = "AdGuard DNS filter";
          id = 1;
        }
        {
          enabled = true;
          url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_2.txt";
          name = "AdAway Default Blocklist";
          id = 2;
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
    allowedTCPPorts = [5353]; # DNS over TCP
    allowedUDPPorts = [5353]; # DNS over UDP

    # Web interface only accessible via Tailscale
    interfaces."tailscale0".allowedTCPPorts = [3000];
  };

  # Ensure AdGuard starts after network is up
  systemd.services.adguardhome = {
    after = ["network-online.target" "tailscaled.service"];
    wants = ["network-online.target"];
  };
}
