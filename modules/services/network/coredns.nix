# CoreDNS configuration for local DNS resolution
#
# ⚠️  UNUSED - Replaced by AdGuard Home DNS rewrites
# This service is redundant and has been removed from hosts.
# AdGuard Home directly handles *.home.jeremyk.net → 100.74.102.74 via DNS rewrites.
#
# Original purpose was to provide .home.jeremyk.net domain resolution,
# but AdGuard DNS rewrites accomplish this more efficiently.
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
