# NixOS Multi-Host Deployment Guide

This repository manages multiple NixOS hosts using Nix flakes and Colmena for deployment orchestration.

## Hosts

- **jeremydesktop**: Primary desktop (localhost)
- **bee**: Beelink Mini PC (192.168.1.245)
- **halo**: Hetzner VPS (46.62.144.212)
- **pi**: Raspberry Pi 4 (192.168.1.230)

## Deployment Process

### Initial Deployment (New Host)

For brand new installations or complete system wipes:

```bash
# Enter development shell for deployment tools
nix develop

# Deploy host (WARNING: This will WIPE the target disk!)
./deploy-host.sh bee root@192.168.1.245        # Deploy bee
./deploy-host.sh halo root@46.62.144.212       # Deploy halo  
./deploy-host.sh pi root@192.168.1.230         # Deploy pi

# IMPORTANT: Do NOT use Tailscale hostnames for initial deployment!
# nixos-anywhere reboots during install and won't reconnect through Tailscale.
# Always use direct IP addresses for initial deployment.

# If deployment hangs at "Uploading install SSH keys", press Ctrl+D
```

### Deploying to Existing NixOS Systems

When colmena can't deploy due to configuration drift:

```bash
# Use --existing-nix flag for existing NixOS systems
./deploy-host.sh --existing-nix halo root@46.62.144.212
./deploy-host.sh --existing-nix bee root@192.168.1.245

# This uses nixos-rebuild instead of nixos-anywhere (no disk wipe)
# Prefer IP addresses over Tailscale hostnames in case network services restart
```

### Configuration Updates (Existing Host)

For updating configuration on already-deployed hosts:

```bash
# Enter development shell
nix develop

# Deploy to specific host(s)
./colmena-deploy.sh bee         # Single host
./colmena-deploy.sh bee halo    # Multiple hosts
./colmena-deploy.sh             # All hosts

# Alternative: Local rebuild for desktop
sudo nixos-rebuild switch --flake .#JeremyDesktop
```

## Adding a New Host

1. **Create host configuration**:
   ```bash
   mkdir -p hosts/newhostname
   # Create hosts/newhostname/default.nix
   # Create hosts/newhostname/disko.nix (for disk layout)
   # Create hosts/newhostname/hardware-configuration.nix
   ```

2. **Add to flake.nix**:
   - Add entry in `nixosConfigurations`
   - Add entry in `colmenaHive`

3. **Configure networking**:
   - Set correct IP in colmena deployment
   - Configure hostname in host's default.nix

4. **Deploy**:
   ```bash
   # Initial deployment (use IP address, not Tailscale hostname!)
   ./deploy-host.sh newhostname root@ip.address
   ```

5. **Post-deployment setup**:
   ```bash
   # Change root password
   ssh root@ip.address 'passwd'
   
   # Get host SSH key for agenix
   ssh root@ip.address "cat /etc/ssh/ssh_host_ed25519_key.pub"
   # Add to secrets.nix and allSystems list, then re-encrypt:
   cd /home/jeremy/dotfiles/nix && agenix --rekey
   
   # Join Tailscale network (all-in-one command)
   # For regular hosts:
   ssh root@ip.address 'tailscale up --ssh'
   # For VPS/exit nodes (like halo):
   ssh root@ip.address 'tailscale up --ssh --advertise-exit-node'
   
   # Deploy any configuration updates
   ./colmena-deploy.sh newhostname
   ```

## Common Tasks

### Managing Secrets with Agenix
```bash
# Edit existing secret
agenix -e secrets/hass_token.age

# Create new secret
agenix -e secrets/new_secret.age

# Re-encrypt all secrets (after adding/removing host keys)
cd /home/jeremy/dotfiles/nix && agenix --rekey

# List all secrets
ls -la secrets/*.age
```

### Check deployment status
```bash
# Test configuration builds
nix build .#nixosConfigurations.hostname.config.system.build.toplevel --dry-run

# Check current system version
ssh root@hostname nixos-version
```

### Rollback a deployment
```bash
# On the target host
sudo nixos-rebuild switch --rollback
```

### Update flake inputs
```bash
nix flake update
./colmena-deploy.sh  # Deploy updates to all hosts
```

## Architecture

- **Common modules** (`hosts/common/`): Shared configuration for all hosts
- **Host-specific** (`hosts/hostname/`): Per-host customization
- **Deployment**: Colmena for orchestration, nixos-anywhere for initial install
- **Secrets**: Agenix-ready (requires host keys in secrets.nix)

## Troubleshooting

### Deployment fails with "no identity matched"
- Host's SSH key not in secrets.nix
- Get key: `ssh root@host "cat /etc/ssh/ssh_host_ed25519_key.pub"`
- Add to secrets.nix and re-encrypt: `cd /home/jeremy/dotfiles/nix && agenix --rekey`

### Cannot SSH after deployment
- Check SSH key is in `hosts/common/ssh.nix`
- Verify firewall allows port 22
- Use console/KVM access with root password (see SECURITY.md)

### Build fails locally
- Ensure you're in nix develop shell
- Check syntax with `nix flake check`
- Review recent changes with `jj diff`