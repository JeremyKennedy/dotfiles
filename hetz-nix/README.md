# NixOS on Hetzner Cloud

Automated NixOS deployment for Hetzner Cloud using nixos-anywhere. Configured as a secure Tailscale-only server with exit node capabilities.

## 🚀 Quick Start

```bash
# 1. Clone and deploy
git clone <your-repo> && cd hetzner
nix run github:nix-community/nixos-anywhere -- --flake .#hetz-nix root@SERVER_IP

# 2. Configure Tailscale (after reboot)
ssh root@SERVER_IP
tailscale up --ssh --advertise-exit-node

# 3. Access via Tailscale
ssh root@hetz-nix.sole-bigeye.ts.net
# Uptime Kuma: http://hetz-nix.sole-bigeye.ts.net:3001

# 4. Deploy updates
nixos-rebuild switch --flake .#hetz-nix --target-host root@hetz-nix.sole-bigeye.ts.net
```

## 📁 Repository Structure

```
.
├── flake.nix           # Nix flake configuration
├── configuration.nix   # Main NixOS system configuration  
├── disk-config.nix     # Disko disk partitioning (LVM on GPT)
└── README.md          # This file
```

## ✅ Prerequisites

- **Local machine**: Nix with flakes enabled
- **Target server**: Fresh Hetzner Cloud instance with SSH root access
- **SSH key**: Your public key in `configuration.nix`

## 🔧 Initial Setup

### 1. Deploy NixOS

```bash
nix run github:nix-community/nixos-anywhere -- --flake .#hetz-nix root@SERVER_IP
```

This automatically:
- Partitions disk with LVM (boot + ESP + root)
- Installs NixOS 
- Applies your configuration
- Reboots into the new system

### 2. Configure Tailscale

```bash
# SSH into the server (still works via public IP initially)
ssh root@SERVER_IP

# Authenticate with Tailscale
tailscale up --ssh --advertise-exit-node

# Get your Tailscale IP
tailscale ip -4
```

### 3. Secure Access

After Tailscale is configured:
- Block port 22 in Hetzner Cloud firewall for public access
- SSH remains available via Tailscale: `ssh root@hetz-nix.sole-bigeye.ts.net`
- Uptime Kuma is accessible at: `http://hetz-nix.sole-bigeye.ts.net:3001`

## 🔄 Ongoing Management

### Update System

Configuration changes are applied with:

```bash
# Always deploy from your local machine:
nixos-rebuild switch --flake .#hetz-nix --target-host root@hetz-nix.sole-bigeye.ts.net
```

Note: The configuration files are not copied to the server during deployment. 
Always manage and deploy changes from your local machine.

### Automatic Maintenance

The system automatically:
- **Updates**: Security patches daily at 2 AM (with reboot if needed)
- **Cleans**: Old generations weekly (keeps last 7 days)
- **Optimizes**: Nix store deduplication
- **Protects**: SSH via fail2ban (3 attempts = ban)

## 🛡️ Security Features

- **SSH**: Key-only authentication (no passwords)
- **Firewall**: Default deny all, explicit allows only
- **Access**: Tailscale-only after initial setup
- **Updates**: Automated security patches
- **Protection**: fail2ban prevents brute force

## 📦 Included Software

- **Shell**: Fish + Starship prompt
- **Editor**: Vim
- **Version Control**: Git + Jujutsu
- **Development**: Claude Code
- **Monitoring**: Uptime Kuma (port 3001)
- **Networking**: Tailscale (exit node enabled)

## ⚙️ Configuration Details

### Network
- Hostname: `hetz-nix`
- Tailscale exit node with IP forwarding
- UDP GRO optimization for performance

### Storage  
- GPT partition table
- 1MB BIOS boot partition
- 500MB ESP partition  
- LVM for root filesystem (ext4)

### Performance
- Zram swap enabled
- `/tmp` cleaned on boot
- Network optimizations for Tailscale

## 🔍 Troubleshooting

### Can't SSH After Deployment
- Ensure your SSH key in `configuration.nix` matches your local key
- Try: `ssh -i /path/to/key root@SERVER_IP`

### Tailscale Not Working
- Check status: `systemctl status tailscaled`
- Re-authenticate: `tailscale up`
- Verify exit node approved in Tailscale admin panel

### Uptime Kuma Not Accessible
- Verify it's running: `systemctl status uptime-kuma`
- Check binding: Should be on Tailscale IP, not localhost
- Access via: `http://TAILSCALE_IP:3001`

## 📝 Notes

- Initial deployment requires public SSH access
- After Tailscale setup, all access can be Tailscale-only
- System state version: NixOS 24.05
- Flake uses nixpkgs-unstable for latest packages