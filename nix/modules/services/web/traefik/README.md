# Traefik Configuration Module

This module provides a modular Traefik reverse proxy configuration with services organized by category.

## Directory Structure

```
traefik/
├── default.nix          # Main Traefik configuration (entrypoints, TLS, middleware)
├── lib.nix              # Helper functions (mkRouter, mkService, mkRedirect)
├── customizations.nix   # Reusable middleware definitions
└── services/            # Service definitions organized by category
    ├── gaming.nix       # Gaming services (crafty)
    ├── media.nix        # Media services (plex, *arr stack)
    ├── monitoring.nix   # Monitoring services (kuma, grafana, etc.)
    ├── network.nix      # Network services (unifi, adguard, traefik dashboard)
    ├── productivity.nix # Productivity services (nextcloud, gitea, homeassistant, etc.)
    ├── redirects.nix    # URL redirects (meet.jeremyk.net)
    └── webhost.nix      # Web hosting services (public-site)
```

## Key Concepts

- **Router**: Receives HTTP requests and routes them based on rules (domains)
- **Service**: Backend servers that handle the actual requests
- **Middleware**: Modifies requests/responses (headers, auth, redirects)

## Service Definition Format

Services are defined in category files with this structure:

```nix
{
  public = {
    service-name = {
      host = "192.168.1.240";     # Backend server IP/hostname
      port = 8080;                 # Backend port
      subdomain = "custom";        # Optional: defaults to service name
      extraHosts = ["alias.com"];  # Optional: additional domains
      middlewares = ["websocket"]; # Optional: extra middleware
      https = true;                # Optional: use HTTPS to backend
      service = "api@internal";    # Optional: override service name
      backend = {                  # Optional: advanced backend config
        responseForwarding.flushInterval = "0s";
      };
    };
  };
  
  tailscale = {
    # Services only accessible via Tailscale VPN
  };
}
```

## Helper Functions

### mkRouter
Creates router configuration from service definition. Automatically:
- Generates domain rules from subdomain
- Applies security headers
- Adds Tailscale restriction for non-public services
- Configures TLS with Let's Encrypt

### mkService  
Creates backend service configuration. Handles:
- HTTP/HTTPS scheme selection
- Load balancer configuration
- Backend customizations

### mkRedirects
Creates both redirect services and their middleware from a single definition. Example:
```nix
redirectDefinitions = {
  meet = {
    from = "meet";
    to = "https://meet.google.com/abc-defg-hij";
    permanent = false;
  };
  old-site = {
    from = "old";
    to = "https://new.example.com";
    permanent = true;
  };
};

generated = helpers.mkRedirects redirectDefinitions;
# Returns: { services = {...}; middleware = {...}; }
```

## Adding New Services

1. Choose the appropriate category file in `services/`
2. Add to either `public` or `tailscale` section:
   ```nix
   myservice = {
     host = "192.168.1.240";
     port = 8080;
   };
   ```
3. Service will be available at `myservice.jeremyk.net`

## Customizations

### Middleware
Reusable middleware are defined in `customizations.nix`:
- `websocket` - WebSocket protocol support
- `cors-allow-all` - Permissive CORS headers
- `basic-auth` - HTTP basic authentication

### Special Cases
- Root domain: Set `subdomain = ""` for jeremyk.net
- Multiple domains: Use `extraHosts = ["alias.com"]`
- Internal services: Use `service = "api@internal"`
- Redirects: Define in `redirects.nix` using the redirectDefinitions pattern

## Notes

- All services get HTTPS via Let's Encrypt DNS challenge
- Public services are accessible from anywhere
- Tailscale services require VPN connection
- Tower host: 192.168.1.240 (most services)
- Bee host: localhost (DNS, Traefik, public site)