#!/usr/bin/env bash
set -euo pipefail

# Deploy bee using nixos-anywhere
# This will wipe the disk and install NixOS with our configuration

echo "This will COMPLETELY WIPE the target machine and install NixOS!"
echo "Target: bee (192.168.1.245)"
echo ""
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Deployment cancelled"
    exit 1
fi

# Ensure we're in the nix directory
cd "$(dirname "$0")"

echo "Building and deploying bee..."
nix run github:nix-community/nixos-anywhere -- \
    --flake .#bee \
    --target-host nixos@192.168.1.245

echo "Deployment complete! You can now SSH to bee using: ssh root@192.168.1.245"