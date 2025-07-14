# List all available commands
default:
    @just --list

# Deploy to specific host(s)
deploy +hosts:
    ./scripts/colmena-deploy.sh {{hosts}}

# Deploy to all hosts
deploy-all:
    ./scripts/colmena-deploy.sh

# Check flake configurations (optionally for specific host(s))
check +hosts="":
    #!/usr/bin/env bash
    if [ -z "{{hosts}}" ]; then
        nix flake check
    else
        for host in {{hosts}}; do
            echo "Checking $host..."
            nix build .#nixosConfigurations.$host.config.system.build.toplevel --dry-run
        done
    fi

# Update flake inputs
update:
    nix flake update

# Format all nix files
fmt:
    nix fmt .

# Test services on all hosts
test-services:
    ./scripts/test-services.sh

# Rebuild local desktop
rebuild:
    sudo nixos-rebuild switch --flake .#navi

# Emergency deploy when colmena fails
deploy-direct host ip:
    ./scripts/deploy-host.sh --existing-nix {{host}} root@{{ip}}

# Build a specific host configuration without deploying
build host:
    nix build .#nixosConfigurations.{{host}}.config.system.build.toplevel

# Enter a host-specific nix shell
shell host:
    nix develop .#nixosConfigurations.{{host}}.config.system.build.toplevel

# Show what would change in a deployment
diff host:
    colmena build --on {{host}}
    @echo "Run 'colmena apply --on {{host}}' to deploy"

# Run garbage collection on a host
gc host:
    ssh root@{{host}} "nix-collect-garbage -d"

# SSH to a host
ssh host:
    ssh root@{{host}}.sole-bigeye.ts.net

# Show system info for all hosts
info:
    @echo "System Information:"
    @echo "=================="
    @for host in navi bee halo pi; do \
        echo -n "$$host: "; \
        nix eval --raw .#nixosConfigurations.$$host.config.system.stateVersion 2>/dev/null || echo "error"; \
    done