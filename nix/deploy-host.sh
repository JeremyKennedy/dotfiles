#!/usr/bin/env bash
set -euo pipefail

# Generic NixOS deployment script using nixos-anywhere
# Usage: ./deploy-host.sh <hostname> <user@ip-address>

if [ $# -lt 2 ]; then
    echo "Usage: $0 <hostname> <user@ip-address>"
    echo "Example: $0 bee root@192.168.1.245"
    echo "Example: $0 halo nixos@46.62.144.212"
    exit 1
fi

HOSTNAME="$1"
TARGET="$2"

# Parse user and IP from the target
if [[ "$TARGET" =~ ^(.*)@(.*)$ ]]; then
    USER="${BASH_REMATCH[1]}"
    IP_ADDRESS="${BASH_REMATCH[2]}"
else
    echo "Error: Target must be in format user@ip-address"
    exit 1
fi

echo "This will COMPLETELY WIPE the target machine and install NixOS!"
echo "Target: $HOSTNAME ($IP_ADDRESS)"
echo "User: $USER"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 1
fi

# Ensure we're in the nix directory
cd "$(dirname "$0")"

echo "Building and deploying $HOSTNAME..."

echo "Starting deployment with nixos-anywhere..."
nix run github:nix-community/nixos-anywhere -- \
    --flake ".#$HOSTNAME" \
    --target-host "$TARGET"

echo "Deployment complete! You can now SSH to $HOSTNAME using: ssh root@$IP_ADDRESS"
echo ""
echo "Next steps:"
echo "1. Change root password: ssh root@$IP_ADDRESS 'passwd'"
echo "2. Get host SSH key for agenix: ssh root@$IP_ADDRESS 'cat /etc/ssh/ssh_host_ed25519_key.pub'"
echo "   Add this key to secrets.nix and re-encrypt secrets with:"
echo "   cd /home/jeremy/dotfiles/nix && agenix --rekey"
echo "3. Join Tailscale network: ssh root@$IP_ADDRESS 'tailscale up'"
echo "4. Enable Tailscale SSH (optional): ssh root@$IP_ADDRESS 'tailscale set --ssh'"
echo "5. Enable exit node (if desired): ssh root@$IP_ADDRESS 'tailscale set --advertise-exit-node'"
echo "6. Deploy configuration updates: ./colmena-deploy.sh $HOSTNAME"