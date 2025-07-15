# Security

## Access Control

### SSH

- Key-based authentication only
- Root login allowed with key only
- Password authentication disabled

### Default Console Password

- Initial root password: `nixos`
- Used for console/KVM access only
- Change immediately: `passwd`

### Service Access

- Internal services: Tailscale-only middleware
- Public services: Explicitly marked in config
- Dashboard access: Tailscale network only

## Network Security

### Firewall

- Ports 80/443 open on bee
- All other services via Tailscale
- Dashboard ports on Tailscale interface only

### Tailscale

- All hosts connected via mesh VPN
- Internal services restricted to 100.64.0.0/10
- Exit nodes available from multiple hosts
- Subnet routing enabled for local network access

## Secrets Management

See [Secrets Guide](../guides/secrets.md) for detailed agenix usage.

## Related Documentation

- [Architecture Overview](../architecture.md) - System architecture
- [Networking](../networking.md) - Firewall and network security
- [Secrets Management](../guides/secrets.md) - Managing encrypted secrets
- [Services Catalog](../services.md) - Service access controls
