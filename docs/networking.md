# Networking

## Network Topology

### External Access

- Router forwards WAN:443 → bee:443 (Traefik)
- Public services accessible at `service.jeremyk.net`
- Internal services at `service.home.jeremyk.net` (Tailscale only)

### Internal Network

- LAN: 192.168.1.0/24
- Tailscale: 100.64.0.0/10
- All hosts connected via Tailscale mesh

## DNS Configuration

### AdGuard Home (bee)

- Port 53 - Standard DNS
- Web UI on port 3000
- Wildcard entries for `*.home.jeremyk.net` → bee
- Ad blocking and filtering enabled

For detailed DNS architecture and configuration, see [DNS documentation](./architecture/dns.md).

## Traefik Routing

### Service Discovery

- Automatic from NixOS configuration
- Services organized in category modules

For complete service listings, see [services documentation](./services.md).

### Middleware

- `tailscale-only`: Restricts to VPN IPs
- `security-headers`: HSTS, XSS protection
- `rate-limit`: For public services

### SSL/TLS

- Let's Encrypt via Cloudflare DNS-01 challenge
- Wildcard certificate for `*.jeremyk.net`
- Auto-renewal configured
- ACME email: me@jeremyk.net
- Certificate storage: `/var/lib/traefik/acme.json`

## Port Mappings

### bee (192.168.1.245)

- 53/udp - DNS (AdGuard)
- 80/tcp - HTTP (Traefik)
- 443/tcp - HTTPS (Traefik)
- 3000/tcp - AdGuard UI
- 9090/tcp - Traefik Dashboard
- 19999/tcp - Netdata

### Common Service Ports

For specific service ports and configurations, see [services documentation](./services.md).

## Firewall Rules

### NixOS Hosts

```nix
networking.firewall = {
  allowedTCPPorts = [80 443];
  interfaces."tailscale0".allowedTCPPorts = [9090];
};
```

### halo (Hetzner VPS)

- Managed via Hetzner Cloud firewall
- Only open port is Tailscale

## Related Documentation

- [Architecture Overview](./architecture.md) - System design and components
- [DNS Architecture](./architecture/dns.md) - DNS configuration details
- [Services Catalog](./services.md) - Service routing and configuration
- [Security Model](./architecture/security.md) - Security practices and firewall rules
- [Deployment Guide](./deployment.md) - Network deployment procedures
