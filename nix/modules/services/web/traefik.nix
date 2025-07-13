# Traefik ingress controller and reverse proxy
#
# Access methods:
# - http://traefik.home                    - Primary access (self-proxied)
# - https://traefik.home.jeremyk.net       - HTTPS access with valid Let's Encrypt certificate
# - http://bee.sole-bigeye.ts.net:9090    - Direct access to dashboard port (Tailscale only)
# - http://100.74.102.74:9090             - Direct access via Tailscale IP
#
# Features:
# - HTTP/HTTPS reverse proxy with automatic redirection
# - Automatic HTTPS with Let's Encrypt
# - Dashboard on port 9090 (Tailscale only)
# - Metrics endpoint for Prometheus
# - Rate limiting and security headers
# - NixOS-native service configuration
#
# To add new services:
# 1. Add router to services.traefik.dynamicConfigOptions.http.routers
# 2. Add service to services.traefik.dynamicConfigOptions.http.services
# Example:
#   myapp = {
#     rule = "Host(`myapp.home`)";
#     service = "myapp";
#     middlewares = ["tailscale-only" "security-headers"];
#     entryPoints = ["websecure"];
#     tls = true;
#   };
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          asDefault = true;
          # No global HTTPS redirect - handle per domain
        };

        websecure = {
          address = ":443";
        };

        # Dashboard endpoint (Tailscale only)
        traefik = {
          address = ":9090";
        };

        # Metrics endpoint (Prometheus)
        metrics = {
          address = "127.0.0.1:8082";
        };
      };

      certificatesResolvers.letsencrypt.acme = {
        email = "me@jeremyk.net";
        storage = "${config.services.traefik.dataDir}/acme.json";
        dnsChallenge = {
          provider = "cloudflare";
          delayBeforeCheck = 10;
          resolvers = ["1.1.1.1:53" "1.0.0.1:53"];
        };
      };

      # API and dashboard configuration
      api = {
        dashboard = true;
        insecure = true; # Expose dashboard on traefik entrypoint (port 9090)
      };

      log = {
        level = "INFO";
        filePath = "${config.services.traefik.dataDir}/traefik.log";
        format = "json";
      };

      accessLog = {
        filePath = "${config.services.traefik.dataDir}/access.log";
        format = "json";
        bufferingSize = 100;
      };

      # Metrics
      metrics = {
        prometheus = {
          entryPoint = "metrics";
          addEntryPointsLabels = true;
          addServicesLabels = true;
        };
      };

      # Ping (health check)
      ping = {
        entryPoint = "web";
      };

      # Global settings
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
    };

    # Dynamic configuration
    dynamicConfigOptions = {
      http = {
        routers = {
          # Traefik dashboard - .home (HTTP only)
          traefik-home = {
            rule = "Host(`traefik.home`)";
            service = "traefik-dashboard";
            middlewares = ["tailscale-only" "security-headers"];
            entryPoints = ["web"];
          };

          # Traefik dashboard - .home.jeremyk.net (HTTPS with auto-redirect)
          traefik-secure = {
            rule = "Host(`traefik.home.jeremyk.net`)";
            service = "traefik-dashboard";
            middlewares = ["tailscale-only" "security-headers"];
            entryPoints = ["web" "websecure"];
            tls = {
              certResolver = "letsencrypt";
            };
          };

          # AdGuard - .home (HTTP only)
          adguard-home = {
            rule = "Host(`adguard.home`)";
            service = "adguard";
            middlewares = ["tailscale-only" "security-headers"];
            entryPoints = ["web"];
          };

          # AdGuard - .home.jeremyk.net (HTTPS with auto-redirect)
          adguard-secure = {
            rule = "Host(`adguard.home.jeremyk.net`)";
            service = "adguard";
            middlewares = ["tailscale-only" "security-headers"];
            entryPoints = ["web" "websecure"];
            tls = {
              certResolver = "letsencrypt";
            };
          };

          # Public website (HTTPS with auto-redirect)
          public-site-router = {
            rule = "Host(`jeremyk.net`) || Host(`www.jeremyk.net`)";
            service = "public-site";
            middlewares = ["security-headers" "rate-limit"];
            entryPoints = ["web" "websecure"];
            tls = {
              certResolver = "letsencrypt";
            };
          };
        };

        middlewares = {
          # Restrict to Tailscale network
          tailscale-only = {
            ipWhiteList = {
              sourceRange = [
                "100.64.0.0/10" # Tailscale CGNAT range
                "fd7a:115c:a1e0::/48" # Tailscale IPv6 range
                "127.0.0.1/32"
                "::1/128"
              ];
            };
          };

          # Security headers
          security-headers = {
            headers = {
              browserXssFilter = true;
              contentTypeNosniff = true;
              forceSTSHeader = true;
              frameDeny = true;
              sslRedirect = false; # Don't force SSL in headers
              stsIncludeSubdomains = true;
              stsPreload = true;
              stsSeconds = 31536000;
              customFrameOptionsValue = "SAMEORIGIN";
              customRequestHeaders = {
                X-Forwarded-Proto = "https";
              };
            };
          };



          # Rate limiting for public services
          rate-limit = {
            rateLimit = {
              average = 10;  # 10 req/min for static site
              burst = 20;    # Allow small bursts
              period = "1m";
            };
          };
        };

        # Services configuration
        services = {
          # AdGuard Home
          adguard = {
            loadBalancer = {
              servers = [
                {url = "http://localhost:3000";}
              ];
            };
          };

          # Traefik Dashboard
          traefik-dashboard = {
            loadBalancer = {
              servers = [
                {url = "http://localhost:9090";}
              ];
            };
          };

          # Public site - returns 200 OK
          public-site = {
            loadBalancer = {
              servers = [
                {url = "http://localhost:8888";}
              ];
            };
          };
        };
      };
    };
  };

  # Traefik service configuration
  services.traefik.dataDir = "/var/lib/traefik";

  # Firewall configuration
  # SECURITY: Only ports 80 and 443 are exposed to the internet
  # Port 9090 (dashboard) is restricted to Tailscale interface only
  networking.firewall = {
    allowedTCPPorts = [80 443];  # Public ports
    
    # Dashboard port 9090 - Tailscale interface ONLY
    # This ensures the dashboard is never exposed to the internet
    interfaces."tailscale0".allowedTCPPorts = [9090];
  };

  # Ensure Traefik starts after network is ready
  systemd.services.traefik = {
    after = ["network-online.target" "tailscaled.service"];
    wants = ["network-online.target"];
    # Cloudflare API credentials for DNS challenge
    serviceConfig = {
      EnvironmentFile = config.age.secrets.cloudflare_dns_token.path;
    };
  };
}
