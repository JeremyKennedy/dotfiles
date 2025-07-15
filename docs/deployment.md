# Deployment Guide

## Quick Reference

### Deploy Commands
```bash
# Deploy single host
just deploy bee

# Deploy multiple hosts  
just deploy bee halo

# Deploy all hosts
just deploy-all

# Check deployment status
colmena exec -- hostname
```

### Common Operations
```bash
# Rebuild local desktop
just rebuild

# Test configuration
just check bee

# Run service tests
just test-services

# View logs
just ssh bee
journalctl -u traefik -f
```

## Initial Host Deployment

### Prerequisites
1. Boot target from NixOS ISO
2. Set root password: `passwd`
3. Note IP address: `ip addr`

### Deploy with nixos-anywhere
```bash
# Using deployment script (recommended)
./deploy-host.sh hostname root@IP_ADDRESS

# Or directly with nixos-anywhere
nix run github:nix-community/nixos-anywhere -- \
  --flake .#hostname \
  root@IP_ADDRESS

# For existing NixOS systems (uses nixos-rebuild, no disk wipe)
./deploy-host.sh --existing-nix hostname root@IP_ADDRESS
```

**Important**: Use IP addresses for initial deployment, not Tailscale hostnames

### Post-Deployment
1. Get host SSH key for secrets:
   ```bash
   ssh root@host 'cat /etc/ssh/ssh_host_ed25519_key.pub'
   ```

2. Add to `secrets.nix`:
   ```nix
   hostname = "ssh-ed25519 AAAA... root@hostname";
   ```

3. Re-encrypt secrets:
   ```bash
   agenix --rekey
   ```

4. Update Colmena target in `flake.nix` to use Tailscale domain

Note: Tailscale is managed declaratively. Use `tailscale_auth_key.age` secret for automatic joining.

## Troubleshooting

For comprehensive troubleshooting guide, see [troubleshooting documentation](./troubleshooting.md).

### Quick Checks
```bash
# Check deployment status
colmena exec -- hostname

# Test services
just test-services

# View logs
ssh root@bee.sole-bigeye.ts.net journalctl -u traefik -f
```

## Adding New Services

1. Add to appropriate category in `/modules/services/network/traefik/services/`
2. Define as either `public` or `tailscale` service
3. Deploy: `just deploy bee`
4. Test: `curl https://service.home.jeremyk.net`

For service organization and available services, see [services documentation](./services.md).

## Related Documentation

- [Architecture Overview](./architecture.md) - System design and components
- [Services Catalog](./services.md) - Available services and configuration
- [Networking](./networking.md) - Network topology and routing
- [Troubleshooting](./troubleshooting.md) - Common issues and solutions
- [Secrets Management](./guides/secrets.md) - Managing encrypted secrets