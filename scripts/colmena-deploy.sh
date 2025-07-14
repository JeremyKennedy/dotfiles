#!/usr/bin/env bash
set -euo pipefail

# Deploy to hosts using colmena
# Usage: ./colmena-deploy.sh [host1] [host2] ...
# If no hosts specified, deploys to all hosts

# Change to the nix directory where flake.nix is located
cd "$(dirname "$0")"

if [ $# -eq 0 ]; then
    echo "Deploying to all hosts..."
    colmena apply --verbose
else
    # Build comma-separated list of hosts for colmena
    HOSTS=$(IFS=,; echo "$*")
    echo "Deploying to: $@"
    colmena apply --verbose --on "$HOSTS"
fi