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

# Test services using modern Python framework
test-services:
    cd scripts/homelab-test && nix develop -c python -m homelab_test.cli

# Test core infrastructure only (Python framework)
test-core:
    cd scripts/homelab-test && nix develop -c python -m homelab_test.cli --core

# Get JSON output
test-json:
    cd scripts/homelab-test && nix develop -c python -m homelab_test.cli --output json

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
    #!/usr/bin/env bash
    ip=$(nix eval --raw --impure --expr "(import ./modules/core/hosts.nix).hosts.{{host}}.ip" 2>/dev/null)
    if [ -n "$ip" ]; then
        ssh root@$ip
    else
        ssh root@{{host}}
    fi

# Show system info for all hosts
info:
    #!/usr/bin/env bash
    echo "System Information:"
    echo "=================="
    for host in navi bee halo pi; do
        printf "%-10s" "$host:"
        state_version=$(nix eval --raw .#nixosConfigurations.$host.config.system.stateVersion 2>/dev/null)
        if [ $? -eq 0 ]; then
            printf "%-10s" "$state_version"
            # Get IP address from hosts.nix
            ip=$(nix eval --raw --impure --expr "(import ./modules/core/hosts.nix).hosts.$host.ip" 2>/dev/null)
            if [ -n "$ip" ]; then
                printf "%-20s" "$ip"
            else
                printf "%-20s" "no IP configured"
            fi
            # Get architecture
            arch=$(nix eval --raw .#nixosConfigurations.$host.config.nixpkgs.hostPlatform.system 2>/dev/null)
            if [ -n "$arch" ]; then
                echo "$arch"
            else
                echo ""
            fi
        else
            echo "configuration not found"
        fi
    done