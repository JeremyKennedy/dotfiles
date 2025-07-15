# DNS Architecture

## Service

**AdGuard Home** (Port 53)

- DNS filtering and ad blocking
- Web UI at http://adguard.home.jeremyk.net (port 3000)
- Shows real client IPs in dashboard
- Declarative NixOS configuration

## Configuration

Wildcard DNS entries in AdGuard:

- `*.home` → 100.74.102.74
- `*.home.jeremyk.net` → 100.74.102.74

All domains point to bee's Tailscale IP for Traefik routing.

## Testing

```bash
dig @100.74.102.74 service.home.jeremyk.net
```

## Related Documentation

- [Architecture Overview](../architecture.md) - System architecture
- [Networking](../networking.md) - Network configuration and DNS integration
- [Troubleshooting](../troubleshooting.md) - DNS troubleshooting guide
