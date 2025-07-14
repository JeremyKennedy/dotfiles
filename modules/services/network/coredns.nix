# CoreDNS configuration for local DNS resolution
#
# Access methods:
# - No web interface (DNS server only)
# - DNS queries on port 5354 (all interfaces)
# - Health check: http://bee.sole-bigeye.ts.net:8080/health (monitoring only)
#
# Features:
# - Secondary DNS server on port 5354 (backup/special cases)
# - Can forward queries to AdGuard Home on port 53 if needed
# - Handles .home domain for local services (if AdGuard DNS rewrites fail)
# - Health check endpoint: http://bee.sole-bigeye.ts.net:8080/health (returns "OK")
#   Used by monitoring tools like Uptime Kuma, not meant for browser access
#
# To add local DNS entries:
# - Edit the hosts section in the config
# - Example: 192.168.1.100 service.home
#
# DNS flow: Client -> AdGuard:53 -> Upstream DNS (CoreDNS:5354 available as backup)
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.coredns = {
    enable = true;
    config = ''
      # Handle .home domain for local services
      home:5354 {
        errors
        health {
          lameduck 5s
        }
        ready

        # Enable query logging for debugging
        log

        # DNS caching
        cache 30

        # Forward all .home queries to local zone
        hosts {
          100.74.102.74 bee.home adguard.home traefik.home dns.home
          fallthrough
        }
      }

      # Handle .home.jeremyk.net domain for HTTPS access using template for wildcard
      home.jeremyk.net:5354 {
        errors
        health {
          lameduck 5s
        }
        ready

        # Enable query logging for debugging
        log

        # DNS caching
        cache 30

        # Use template plugin for wildcard support
        template IN A home.jeremyk.net {
          match ^([a-zA-Z0-9-]+\.)?home\.jeremyk\.net\.$
          answer "{{ .Name }} 300 IN A 100.74.102.74"
          fallthrough
        }
      }

      # Handle all other domains
      .:5354 {
        errors
        health {
          lameduck 5s
        }
        ready

        # Enable query logging
        log

        # DNS caching with longer TTL for external queries
        cache 300

        # Forward to AdGuard Home for filtering
        forward . 127.0.0.1:53 {
          max_concurrent 100
          # Health check for upstream
          health_check 5s
        }

        # Enable DNS over TLS for privacy
        # forward . tls://1.1.1.1 tls://1.0.0.1 {
        #   tls_servername cloudflare-dns.com
        #   health_check 5s
        # }
      }
    '';
  };

  # Ensure CoreDNS starts after AdGuard
  systemd.services.coredns = {
    after = lib.mkForce ["network-online.target" "adguardhome.service"];
    wants = ["network-online.target"];
  };

  # Open firewall for DNS on alternative port
  networking.firewall = {
    allowedTCPPorts = [5354];
    allowedUDPPorts = [5354];
  };

  # Disable systemd-resolved on DNS servers
  services.resolved.enable = lib.mkForce false;
}
