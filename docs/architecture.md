# Homelab Architecture

## Overview

NixOS-based multi-host homelab with declarative configuration and Tailscale networking.

## Hosts

| Host      | Role                | IP            | Services                         |
| --------- | ------------------- | ------------- | -------------------------------- |
| **navi**  | Desktop workstation | 192.168.1.250 | Development environment          |
| **bee**   | Network services    | 192.168.1.245 | DNS (AdGuard), Ingress (Traefik) |
| **halo**  | VPS monitoring      | 46.62.144.212 | Uptime Kuma                      |
| **tower** | Application server  | 192.168.1.240 | Unraid applications              |
| **pi**    | Raspberry Pi        | 192.168.1.230 | (offline)                        |

For Tailscale IPs and domains, see `/modules/core/hosts.nix`.

## Key Components

### Networking

- **Tailscale**: Secure VPN mesh network for all hosts
- **Traefik**: Reverse proxy handling ingress for all services (see [services](./services.md))
- **AdGuard Home**: Primary DNS with ad blocking (see [DNS architecture](./architecture/dns.md))
- **Domain**: `*.home.jeremyk.net` for internal services

For detailed network configuration, see [networking documentation](./networking.md).

### Security

- Internal services protected by `tailscale-only` middleware
- Public services explicitly marked in configuration
- Let's Encrypt SSL via Cloudflare DNS challenge
- Firewall restricted to ports 80/443 + Tailscale

For security model and practices, see [security architecture](./architecture/security.md).

### Monitoring

- **Netdata**: Real-time metrics on all NixOS hosts
- **Uptime Kuma**: Service availability monitoring
- **Test Framework**: Python-based health checks (`just test-services`)

### Configuration

- **NixOS + Flakes**: Declarative system configuration
- **Colmena**: Multi-host deployment tool (see [deployment guide](./deployment.md))
- **Modules**: Reusable configurations in `/modules/` (see [modules guide](./modules.md))
- **Secrets**: Age-encrypted with agenix (see [secrets management](./guides/secrets.md))

## Service Architecture

```
Internet → Router (port 443) → bee (Traefik)
                                    ├── Public Services → Direct/SWAG
                                    └── Internal Services → Tailscale Only
```

For detailed service listings and configuration, see [services documentation](./services.md).

## Related Documentation

- [Deployment Guide](./deployment.md) - How to deploy changes to hosts
- [Services Catalog](./services.md) - Complete list of available services
- [Networking](./networking.md) - Network topology and configuration
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions
- [Module System](./modules.md) - Understanding NixOS modules
