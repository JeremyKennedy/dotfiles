# Traefik Configuration Module

This module provides a modular Traefik reverse proxy configuration with services organized by category.

## Directory Structure

```
traefik/
├── default.nix          # Main Traefik configuration (entrypoints, TLS, middleware)
├── lib.nix              # Helper functions for generating Traefik configs
├── customizations.nix   # Reusable middleware definitions
└── services/            # Service definitions organized by category
    ├── gaming.nix       # Gaming services (Minecraft, game servers)
    ├── media.nix        # Media services (Plex, *arr stack, e-books)
    ├── monitoring.nix   # Monitoring services (uptime, metrics, home automation)
    ├── network.nix      # Network services (DNS, network management)
    ├── productivity.nix # Productivity services (files, documents, development)
    ├── redirects.nix    # URL redirects (vanity URLs, shortcuts)
    └── webhost.nix      # Web hosting services (static websites)
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

## Adding New Services

1. Choose the appropriate category file in `services/`
2. Add to either `public` or `tailscale` section:
   ```nix
   myservice = {
     host = "192.168.1.240";
     port = 8080;
   };
   ```
3. Service will be available at:
   - Public services: `myservice.jeremyk.net`
   - Tailscale services: `myservice.home.jeremyk.net`

## Customizations

### Middleware
Reusable middleware are defined in `customizations.nix`:
- `security-headers` - Security headers (applied to all services)
- `tailscale-only` - Restricts access to Tailscale IPs (auto-applied to internal services)
- `websocket` - WebSocket protocol support
- `cors-allow-all` - Permissive CORS headers
- `basic-auth` - HTTP basic authentication

### Special Cases
- Root domain: Set `subdomain = ""` for jeremyk.net
- Multiple domains: Use `extraHosts = ["alias.com"]`
- Redirects: Define in `redirects.nix` using the redirectDefinitions pattern
- Traefik dashboard: Hardcoded in default.nix at `traefik.home.jeremyk.net` (uses `api@internal` service)

## Domain Strategy

This configuration uses a security-first approach with domain separation:

- **Public services**: `service.jeremyk.net` - Accessible from anywhere
- **Internal services**: `service.home.jeremyk.net` - Only resolvable within Tailscale network

This provides fail-fast security:
1. DNS resolution fails immediately for unauthorized access to internal services
2. Traefik middleware provides additional access control if DNS is bypassed
3. Services are only accessible via Tailscale VPN

## Notes

- All services get HTTPS via Let's Encrypt DNS challenge
- Domain is automatically selected based on service type (public/tailscale)
- Tower host: 192.168.1.240 (Unraid server, most services)
- Bee host: localhost (DNS, Traefik, public site)
- Halo host: 46.62.144.212 (Hetzner VPS, public monitoring)

## Troubleshooting

If Traefik isn't routing your services, check these common issues:

### 1. Check if routers are loaded
```bash
# View all configured routers
curl -s http://bee.sole-bigeye.ts.net:9090/api/http/routers | jq -r '.[].name' | sort

# Should show your service routers, not just internal ones (api@internal, dashboard@internal, etc.)
```

### 2. Check Traefik logs for configuration errors
```bash
# Check for errors in the Traefik log
ssh root@bee.sole-bigeye.ts.net "tail -100 /var/lib/traefik/traefik.log | jq 'select(.level == \"error\")'"

# Common errors:
# - "field not found" - incorrect middleware/service field names
# - "connection refused" - backend service not running
# - "no route to host" - wrong IP/hostname for backend
```

### 3. Verify service is running
```bash
# Test backend service directly
ssh root@bee.sole-bigeye.ts.net "curl -I http://localhost:PORT"

# Check service status
ssh root@bee.sole-bigeye.ts.net "systemctl status SERVICE_NAME"
```

### 4. Check generated configuration
```bash
# View what Nix generated for a specific router
nix eval .#nixosConfigurations.bee.config.services.traefik.dynamicConfigOptions.http.routers.SERVICE_NAME --json | jq

# Check if your service is in the configuration
nix eval .#nixosConfigurations.bee.config.services.traefik.dynamicConfigOptions.http.routers --json | jq 'keys'
```

### 5. Restart Traefik after fixes
```bash
# Deploy configuration changes
just deploy bee

# Or just restart Traefik
ssh root@bee.sole-bigeye.ts.net "systemctl restart traefik"
```

### 6. Test with curl
```bash
# Test routing by forcing resolution to bee
curl -I https://SERVICE.jeremyk.net --resolve SERVICE.jeremyk.net:443:192.168.1.245

# Test internal services via Tailscale
curl -I https://SERVICE.home.jeremyk.net
```