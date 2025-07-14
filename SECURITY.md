# Security Configuration

## Default Passwords

⚠️ **IMPORTANT**: The following default passwords are configured for initial deployment. You MUST change these immediately after first login.

### Root Password (Console/KVM Access)
- **Default Password**: `nixos`
- **Where Used**: Console/KVM access only (SSH uses key-based auth)
- **Configuration**: `hosts/common/base.nix`
- **How to Change**: 
  ```bash
  # After logging in via console
  passwd
  ```

### SSH Access
- **Method**: Key-based authentication only
- **Authorized Key**: SSH key in `hosts/common/ssh.nix`
- **Root Login**: Allowed with SSH key only (`PermitRootLogin prohibit-password`)
- **Password Auth**: Disabled

## Post-Deployment Security Checklist

After deploying a new host:

1. [ ] Login via console/KVM and change root password
2. [ ] Verify SSH key-based access is working
3. [ ] Ensure firewall is enabled and configured
4. [ ] Review open ports: `sudo ss -tlnp`
5. [ ] Check fail2ban is active: `sudo systemctl status fail2ban` (VPS only)
6. [ ] Update system: `sudo nixos-rebuild switch`

## Secret Management (Agenix)

This repository uses agenix for managing encrypted secrets:

### Adding a New Host to Agenix

1. Get the host's SSH public key:
   ```bash
   ssh root@hostname "cat /etc/ssh/ssh_host_ed25519_key.pub"
   ```

2. Add the key to `secrets.nix`:
   ```nix
   hostname = "ssh-ed25519 AAAAC3NzaC1... root@hostname";
   # Add to allSystems list
   allSystems = [ jeremyDesktop hostname ];
   ```

3. Re-encrypt all secrets:
   ```bash
   agenix -r
   ```

### Managing Secrets

- View/edit a secret: `agenix -e secrets/secret_name.age`
- Create new secret: `agenix -e secrets/new_secret.age`
- Secrets are automatically decrypted on target hosts during activation
- Never commit plaintext secrets to the repository

## Network Security

### Tailscale Setup

Tailscale is configured on all hosts for secure networking:

1. **Initial Setup** (after deployment):
   ```bash
   ssh root@hostname
   tailscale up
   # Follow the authentication URL
   ```

2. **Configuration**:
   - All hosts trust the Tailscale interface (`tailscale0`)
   - Halo is configured as an exit node (internet gateway)
   - Routing is enabled for subnet access

3. **Verification**:
   ```bash
   tailscale status              # Check connection status
   tailscale ping hostname       # Test connectivity
   ```

### Firewall Configuration

- Firewall allows only necessary services
- SSH (port 22) is open on public interfaces
- All Tailscale traffic is trusted
- Host-specific ports configured in each host's configuration