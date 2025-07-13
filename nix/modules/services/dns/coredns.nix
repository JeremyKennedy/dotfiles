# CoreDNS configuration for local DNS resolution
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
      home:53 {
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
          # Add static entries for local services here
          # Example: 192.168.1.100 service.home

          fallthrough
        }

        # If not found in hosts, return NXDOMAIN
        template ANY ANY {
          rcode NXDOMAIN
        }
      }

      # Handle all other domains
      .:53 {
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
        forward . 127.0.0.1:5353 {
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

  # Open firewall for DNS
  networking.firewall = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
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
