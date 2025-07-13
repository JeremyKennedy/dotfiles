# Traefik Module - AI Agent Guide

This guide is for AI agents working with the Traefik configuration. For user documentation, see README.md.

## Quick Context

This module implements a modular Traefik reverse proxy configuration with:
- Services organized by category in `services/` directory
- Helper functions in `lib.nix` for DRY configuration
- Automatic domain separation (public vs internal)
- Middleware definitions in `customizations.nix`

## Key Implementation Details

### Service Definition Processing
1. Services are defined in category files with `public` and `tailscale` sections
2. `lib.nix` contains `mkRouter`, `mkService`, and `mkRedirects` helper functions
3. `default.nix` imports all services and generates the final configuration

### Important Quirks
- **CORS Headers**: Use `accessControlAllowOriginList` (not `accessControlAllowOrigin`)
- **Response Forwarding**: Must be under `loadBalancer.responseForwarding`
- **Service Override**: `config.service` is required for redirects (cannot be removed)
- **Dynamic Config**: NixOS module uses file provider automatically

### Common Errors and Solutions
See README.md troubleshooting section for:
- "field not found" errors → Check field names against Traefik docs
- No routers loading → Configuration error preventing file provider
- Service not found → For redirects, ensure service is set to "noop@internal"

### Testing Changes
```bash
# Quick validation
nix eval .#nixosConfigurations.bee.config.services.traefik.dynamicConfigOptions --json | jq 'keys'

# Deploy and check
just deploy bee && sleep 5 && curl -s http://bee.sole-bigeye.ts.net:9090/api/http/routers | jq -r '.[].name' | sort
```

## References
- Traefik v3 Docs: https://doc.traefik.io/traefik/
- NixOS Module Source: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/web-servers/traefik.nix