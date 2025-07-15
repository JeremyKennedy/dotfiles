# Services Catalog

## Service Organization

Services are defined in `/modules/services/network/traefik/services/` by category. All services are routed through Traefik on bee (see [networking](./networking.md)).

### Media Services (`media.nix`)

- **Plex** - Media server
- **Radarr/Sonarr/Prowlarr** - Media automation (\*arr stack)
- **Bazarr** - Subtitle management
- **Deluge** - BitTorrent client
- **Tautulli** - Plex statistics
- **Overseerr** - Media requests
- **Tdarr** - Media transcoding
- **Calibre** - E-book management
- **NZBGet** - Usenet downloader

### Productivity Services (`productivity.nix`)

Public:

- **Nextcloud** - File sync and collaboration
- **Gitea** - Git repository hosting
- **Microbin** - Pastebin service
- **Immich** - Photo management
- **Mealie** - Recipe manager
- **Kutt** - URL shortener

Internal (Tailscale only):

- **Paperless** - Document management
- **Grist** - Spreadsheet database
- **Kimai** - Time tracking
- **Overleaf** - LaTeX editor
- **Home Assistant** - Home automation

### Network Services (`network.nix`)

- **AdGuard Home** - DNS filtering (primary interface)
- **Traefik Dashboard** - Reverse proxy management

### Monitoring Services (`monitoring.nix`)

- **Uptime Kuma** - Service monitoring
- **Grafana** - Metrics visualization
- **Netdata** - Real-time system metrics
- **Scrutiny** - Hard drive health
- **Speedtest Tracker** - Internet speed history
- **Teslamate** - Tesla data logging

### Gaming Services (`gaming.nix`)

- **Crafty** - Minecraft server management

### Web Hosting (`webhost.nix`)

- **SWAG** - Nginx reverse proxy (legacy)
- **Changes** - Website change tracking

## Adding a New Service

1. Choose appropriate category file in `/modules/services/network/traefik/services/`
2. Add service definition:

```nix
# For public service
public = {
  myservice = {
    host = "tower.sole-bigeye.ts.net";
    port = 8080;
    subdomain = "myapp";  # Optional, defaults to service name
  };
};

# For internal service (Tailscale only)
tailscale = {
  myservice = {
    host = "tower.sole-bigeye.ts.net";
    port = 8080;
  };
};
```

3. Deploy: `just deploy bee`
4. Access at `myservice.jeremyk.net` (public) or `myservice.home.jeremyk.net` (internal)

For deployment procedures, see [deployment guide](./deployment.md).

## Related Documentation

- [Architecture Overview](./architecture.md) - System design and service architecture
- [Networking](./networking.md) - How services are routed through Traefik
- [Deployment Guide](./deployment.md) - How to deploy service changes
- [Troubleshooting](./troubleshooting.md) - Debugging service issues
- [Security Model](./architecture/security.md) - Service access controls
