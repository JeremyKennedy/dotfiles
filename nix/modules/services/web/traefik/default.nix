# Traefik ingress controller and reverse proxy
#
# This configuration provides the general scaffolding for Traefik.
# Service-specific configurations are in separate category files.
{
  config,
  pkgs,
  lib,
  ...
}: let
  # Import helper functions
  helpers = import ./lib.nix {inherit lib;};

  # Import service categories
  media = import ./services/media.nix {inherit lib;};
  productivity = import ./services/productivity.nix {inherit lib;};
  monitoring = import ./services/monitoring.nix {inherit lib;};
  network = import ./services/network.nix {inherit lib;};
  gaming = import ./services/gaming.nix {inherit lib;};
  webhost = import ./services/webhost.nix {inherit lib;};
  redirects = import ./services/redirects.nix {inherit lib;};

  # Import customizations from SWAG migration
  customizations = import ./customizations.nix {inherit lib;};

  # Combine all services
  services = {
    inherit media productivity monitoring network gaming webhost redirects;
  };

  # Generate configurations using helper functions
  configs = helpers.generateConfigs services;
  
  # Get redirect middleware from redirects service file
  redirectMiddleware = redirects.middleware or {};
in {
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          asDefault = true;
        };

        websecure = {
          address = ":443";
        };

        traefik = {
          address = ":9090";
        };

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

      api = {
        dashboard = true;
        insecure = true;
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

      metrics = {
        prometheus = {
          entryPoint = "metrics";
          addEntryPointsLabels = true;
          addServicesLabels = true;
        };
      };

      ping = {
        entryPoint = "web";
      };

      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      # Transport settings to match SWAG proxy.conf
      serversTransport = {
        insecureSkipVerify = true; # For self-signed certs
        maxIdleConnsPerHost = 32;
        forwardingTimeouts = {
          dialTimeout = "30s";
          responseHeaderTimeout = "240s"; # Match proxy_read_timeout
          idleConnTimeout = "90s";
        };
      };
    };

    # Dynamic configuration
    dynamicConfigOptions = {
      http = {
        routers = configs.routers // {
          # Hardcoded Traefik dashboard router (special case)
          traefik-dashboard = {
            rule = "Host(`traefik.home.jeremyk.net`)";
            service = "api@internal";
            middlewares = ["security-headers" "tailscale-only"];
            entryPoints = ["web" "websecure"];
            tls = {certResolver = "letsencrypt";};
          };
        };

        middlewares =
          {
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

            # Security headers with standard proxy headers
            security-headers = {
              headers = {
                browserXssFilter = true;
                contentTypeNosniff = true;
                forceSTSHeader = true;
                frameDeny = true;
                sslRedirect = false;
                stsIncludeSubdomains = true;
                stsPreload = true;
                stsSeconds = 31536000;
                customFrameOptionsValue = "SAMEORIGIN";
                customRequestHeaders = {
                  # Standard proxy headers (Traefik adds most automatically)
                  "X-Forwarded-Proto" = "https";
                };
              };
            };

            # Rate limiting for public services
            rate-limit = {
              rateLimit = {
                average = 10;
                burst = 20;
                period = "1m";
              };
            };
          }
          // customizations.middleware // redirectMiddleware;

        # Services configuration
        services = configs.services;
      };
    };
  };

  # Traefik service configuration
  services.traefik.dataDir = "/var/lib/traefik";

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [80 443];
    interfaces."tailscale0".allowedTCPPorts = [9090];
  };

  # Ensure Traefik starts after network is ready
  systemd.services.traefik = {
    after = ["network-online.target" "tailscaled.service"];
    wants = ["network-online.target"];
    serviceConfig = {
      EnvironmentFile = config.age.secrets.cloudflare_dns_token.path;
    };
  };
}
