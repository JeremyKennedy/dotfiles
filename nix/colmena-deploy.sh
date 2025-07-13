#!/usr/bin/env bash
set -euo pipefail

# Deploy to hosts using colmena
# Usage: ./colmena-deploy.sh [host1] [host2] ...
# If no hosts specified, deploys to all hosts

cd "$(dirname "$0")"

if [ $# -eq 0 ]; then
    echo "Deploying to all hosts..."
    colmena apply --verbose
else
    echo "Deploying to: $@"
    colmena apply --verbose --on "$@"
fi