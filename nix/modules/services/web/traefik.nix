# Traefik ingress controller and reverse proxy
{
  config,
  pkgs,
  lib,
  ...
}: {
  services.traefik = {
    enable = true;

    staticConfigOptions = {
      # Global configuration
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };

      # API and dashboard configuration
      api = {
        dashboard = true;
        debug = false;
        insecure = false; # Require authentication
      };

      # Entrypoints configuration
      entryPoints = {
        web = {
          address = ":80";
          http = {
            # Redirect all HTTP to HTTPS
            redirections = {
              entryPoint = {
                to = "websecure";
                scheme = "https";
                permanent = true;
              };
            };
          };
        };

        websecure = {
          address = ":443";
          http = {
            tls = {
              certResolver = "default";
            };
          };
        };

        # Metrics endpoint (Prometheus)
        metrics = {
          address = "127.0.0.1:8082";
        };
      };

      # Certificate resolvers
      certificatesResolvers = {
        default = {
          acme = {
            email = "admin@home.local";
            storage = "/var/lib/traefik/acme.json";
            # Use Let's Encrypt staging for testing
            # caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
            caServer = "https://acme-v02.api.letsencrypt.org/directory";
            httpChallenge = {
              entryPoint = "web";
            };
          };
        };
      };

      # Provider configuration
      providers = {
        # File provider for static configuration
        file = {
          directory = "/etc/traefik/conf.d";
          watch = true;
        };

        # Docker provider (if needed in future)
        # docker = {
        #   endpoint = "unix:///var/run/docker.sock";
        #   exposedByDefault = false;
        #   network = "traefik";
        # };
      };

      # Logging
      log = {
        level = "INFO";
        filePath = "/var/log/traefik/traefik.log";
        format = "json";
      };

      accessLog = {
        filePath = "/var/log/traefik/access.log";
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
    };

    # Dynamic configuration
    dynamicConfigOptions = {
      http = {
        routers = {
          # Dashboard router - only accessible via Tailscale
          dashboard = {
            rule = "Host(`traefik.home`) && (PathPrefix(`/api`) || PathPrefix(`/dashboard`))";
            service = "api@internal";
            middlewares = ["dashboard-auth" "tailscale-only"];
            tls = {
              certResolver = "default";
            };
          };
        };

        middlewares = {
          # Basic auth for dashboard
          dashboard-auth = {
            basicAuth = {
              # Generate with: htpasswd -nb admin password
              # Default: admin/admin (CHANGE THIS!)
              users = [
                "admin:$2y$10$0Nt7WkVa7HxZDpN0IF7p7OqOYWyBQ8DqhzXbdA0cGpSgYqBsMNL0y"
              ];
            };
          };

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
              sslRedirect = true;
              stsIncludeSubdomains = true;
              stsPreload = true;
              stsSeconds = 31536000;
              customFrameOptionsValue = "SAMEORIGIN";
              customRequestHeaders = {
                X-Forwarded-Proto = "https";
              };
            };
          };

          # Rate limiting
          rate-limit = {
            rateLimit = {
              average = 100;
              burst = 50;
              period = "1m";
            };
          };
        };

        # Services configuration (examples)
        services = {
          # Example service for Uptime Kuma
          # uptime-kuma = {
          #   loadBalancer = {
          #     servers = [
          #       { url = "http://localhost:3001"; }
          #     ];
          #   };
          # };
        };
      };
    };
  };

  # Create configuration directory
  systemd.tmpfiles.rules = [
    "d /etc/traefik/conf.d 0755 traefik traefik -"
    "d /var/log/traefik 0755 traefik traefik -"
  ];

  # Firewall configuration
  networking.firewall = {
    allowedTCPPorts = [80 443];

    # Dashboard only via Tailscale
    interfaces."tailscale0".allowedTCPPorts = [8080];
  };

  # Ensure Traefik starts after network is ready
  systemd.services.traefik = {
    after = ["network-online.target" "tailscaled.service"];
    wants = ["network-online.target"];
  };
}
