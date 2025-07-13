#!/usr/bin/env bash
set -euo pipefail

# Generic NixOS deployment script using nixos-anywhere or nixos-rebuild
# Usage: ./deploy-host.sh [--existing-nix] <hostname> <user@ip-address>

EXISTING_NIX=false

# Check for --existing-nix flag as first argument
if [ "$1" = "--existing-nix" ]; then
    EXISTING_NIX=true
    shift # Remove the flag from arguments
fi

# Parse remaining arguments
if [ $# -lt 2 ]; then
    echo "Usage: $0 [--existing-nix] <hostname> <user@ip-address>"
    echo "Example: $0 bee root@192.168.1.245                      # Full install with nixos-anywhere"
    echo "Example: $0 --existing-nix halo root@hetz.net           # Deploy to existing NixOS system"
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

if [ "$EXISTING_NIX" = true ]; then
    echo "Deploying to existing NixOS system (fallback when colmena isn't working)"
    echo "Target: $HOSTNAME ($IP_ADDRESS)"
    echo "User: $USER"
    echo ""
    read -p "Continue with deployment? (yes/no): " confirm
else
    echo "This will COMPLETELY WIPE the target machine and install NixOS!"
    echo "Target: $HOSTNAME ($IP_ADDRESS)"
    echo "User: $USER"
    echo ""
    read -p "Are you sure? (yes/no): " confirm
fi

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 1
fi

# Ensure we're in the nix directory
cd "$(dirname "$0")"

echo "Building and deploying $HOSTNAME..."

if [ "$EXISTING_NIX" = true ]; then
    echo "Starting deployment with nixos-rebuild..."
    nixos-rebuild switch \
        --flake ".#$HOSTNAME" \
        --target-host "$TARGET" \
        --use-remote-sudo
else
    echo "Starting deployment with nixos-anywhere..."
    echo ""
    echo "WARNING: Do NOT use Tailscale hostnames for initial deployment!"
    echo "         nixos-anywhere reboots during install and won't reconnect through Tailscale."
    echo "         Use the direct IP address instead."
    echo ""
    echo "NOTE: If deployment hangs at 'Uploading install SSH keys', press Ctrl+D"
    echo "      This happens when ssh-copy-id waits for password input despite key auth working"
    echo ""
    nix run github:nix-community/nixos-anywhere -- \
        --flake ".#$HOSTNAME" \
        --target-host "$TARGET"
fi

echo "Deployment complete! You can now SSH to $HOSTNAME using: ssh root@$IP_ADDRESS"
echo ""

if [ "$EXISTING_NIX" = true ]; then
    echo "System successfully updated!"
    echo ""
    echo "Note: For regular configuration updates, use: ./colmena-deploy.sh $HOSTNAME"
else
    echo "Next steps:"
    echo "1. Change root password: ssh root@$IP_ADDRESS 'passwd'"
    echo "2. Get host SSH key for agenix: ssh root@$IP_ADDRESS 'cat /etc/ssh/ssh_host_ed25519_key.pub'"
    echo "   Add this key to secrets.nix and re-encrypt secrets with:"
    echo "   cd /home/jeremy/dotfiles/nix && agenix --rekey"
    echo "3. Join Tailscale network: ssh root@$IP_ADDRESS 'tailscale up'"
    echo "4. Enable Tailscale SSH (optional): ssh root@$IP_ADDRESS 'tailscale set --ssh'"
    echo "5. Enable exit node (if desired): ssh root@$IP_ADDRESS 'tailscale set --advertise-exit-node'"
    echo "6. Deploy configuration updates: ./colmena-deploy.sh $HOSTNAME"
fi