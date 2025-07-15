# Troubleshooting Guide

## Common Issues

### DNS Resolution Problems

**Symptoms**: Services not resolving, `*.home.jeremyk.net` not working

**Debug**:

```bash
# Test DNS resolution
dig @100.74.102.74 service.home.jeremyk.net

# Check AdGuard is running
ssh root@bee 'systemctl status adguardhome'

# View AdGuard logs
ssh root@bee 'journalctl -u adguardhome -f'

# Quick DNS test on bee
ssh root@bee '/etc/homelab-test/dns-test.sh'
```

**Common fixes**:

- Ensure client DNS points to bee (192.168.1.245)
- Check AdGuard rewrites configuration (see [DNS architecture](./architecture/dns.md))
- Verify Tailscale is connected

### Service Not Accessible

**Symptoms**: 404/502 errors, timeouts

**Debug**:

```bash
# Check if service is in Traefik
ssh root@bee '/etc/homelab-test/traefik-test.sh'

# Test direct connectivity
curl -I https://service.home.jeremyk.net

# Check Traefik logs
ssh root@bee 'journalctl -u traefik -f'

# Comprehensive test from desktop
just test-services
```

**Common fixes**:

- Verify service is defined in correct category file
- Check host is reachable via Tailscale
- Ensure service port is correct
- Deploy changes: `just deploy bee`

### Tailscale Connection Issues

**Symptoms**: Can't reach internal services, Tailscale offline

**Debug**:

```bash
# Check Tailscale status
tailscale status

# On remote host
ssh root@host 'tailscale status'

# Re-authenticate if needed
ssh root@host 'tailscale up'
```

### Deployment Failures

**Symptoms**: Colmena deploy fails, configuration errors

**Debug**:

```bash
# Check configuration
nix flake check

# Build specific host
just build hostname

# View detailed error
just deploy hostname --show-trace

# Try direct deployment
./deploy-host.sh --existing-nix hostname root@IP
```

For complete deployment procedures, see [deployment guide](./deployment.md).

### Certificate Issues

**Symptoms**: SSL warnings, certificate errors

**Debug**:

```bash
# Check Traefik certificates
ssh root@bee 'ls -la /var/lib/traefik/acme.json'

# View certificate logs
ssh root@bee 'journalctl -u traefik | grep -i cert'

# Test SSL
openssl s_client -connect service.jeremyk.net:443
```

**Common fixes**:

- Verify Cloudflare DNS token is correct
- Check domain DNS points to correct IP
- Ensure Let's Encrypt rate limits not hit
- Wait for rate-limitign to reset

### Service Won't Start

**Debug**:

```bash
# Check service status
ssh root@host 'systemctl status service-name'

# View service logs
ssh root@host 'journalctl -u service-name -n 100'

# Check configuration syntax
nix eval .#nixosConfigurations.hostname.config.services.service-name
```

## Quick Health Check

From desktop:

```bash
# Run comprehensive tests
just test-services

# Check all hosts
colmena exec -- hostname

# View service status on all hosts
colmena exec -- systemctl status
```

On specific host:

```bash
# Run local debug scripts
/etc/homelab-test/dns-test.sh
/etc/homelab-test/service-test.sh
/etc/homelab-test/traefik-test.sh
```

## Related Documentation

- [Architecture Overview](./architecture.md) - Understanding system design
- [Deployment Guide](./deployment.md) - Deployment procedures
- [Services Catalog](./services.md) - Service configuration details
- [Networking](./networking.md) - Network troubleshooting
- [DNS Architecture](./architecture/dns.md) - DNS-specific issues
