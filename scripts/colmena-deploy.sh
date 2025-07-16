#!/usr/bin/env bash
set -euo pipefail

# Deploy to hosts using colmena
# Usage: ./colmena-deploy.sh [host1] [host2] ...
# If no hosts specified, deploys to all hosts

# Change to the nix directory where flake.nix is located
cd "$(dirname "$0")"

# Function to record deployment time
record_deploy_time() {
    local host=$1
    python3 -c "
from pathlib import Path
import json
from datetime import datetime, timezone

deploy_log = Path.home() / '.deploy-times.json'
times = {}
if deploy_log.exists():
    with open(deploy_log) as f:
        times = json.load(f)

times['$host'] = datetime.now(tz=timezone.utc).isoformat()

with open(deploy_log, 'w') as f:
    json.dump(times, f, indent=2)
" 2>/dev/null || true
}

if [ $# -eq 0 ]; then
    echo "Deploying to all hosts..."
    # Record deployment for all hosts
    for host in navi bee halo pi; do
        record_deploy_time "$host"
    done
    colmena apply --verbose
else
    # Build comma-separated list of hosts for colmena
    HOSTS=$(IFS=,; echo "$*")
    echo "Deploying to: $@"
    # Record deployment for specified hosts
    for host in "$@"; do
        record_deploy_time "$host"
    done
    colmena apply --verbose --on "$HOSTS"
fi