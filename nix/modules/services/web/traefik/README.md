# Traefik Configuration Architecture

This directory contains the modular Traefik configuration for migrating from SWAG.

## Files

- `customizations.nix` - Service-specific customizations migrated from SWAG proxy-confs
  - Special middleware (Plex headers, upload limits, WebSocket support)
  - API bypass routes (for services that need unauthenticated API access)
  - Service backend customizations (special ports, buffering settings)
  - Host aliases from SWAG configurations

## Key Design Decisions

1. **DRY Principle**: Services are defined in simple attribute sets with just their port numbers. The `mkRouter` and `mkService` helpers generate the full configuration.

2. **Separation of Concerns**:
   - Main `traefik.nix` defines the service lists and uses helpers
   - `customizations.nix` contains all the special cases and overrides
   - Helpers automatically apply customizations when generating configs

3. **Public vs Tailscale**: Services are separated into two lists based on their access requirements. The `mkRouter` helper automatically applies the correct middleware.

4. **API Bypass Routes**: Some services (HomeAssistant, Bitwarden, Immich) need their API endpoints accessible without Tailscale auth. These are defined with higher priority routes.

5. **Compatibility with SWAG**: All special headers, timeouts, and configurations from SWAG proxy-confs are preserved.

## Adding New Services

1. Add to either `publicServices` or `tailscaleServices` in the main traefik.nix:
   ```nix
   myservice = { port = 8080; };
   ```

2. If the service needs special configuration, add to customizations.nix:
   - Router customizations (extra middleware, domains)
   - Service customizations (special backends, buffering)
   - API bypass routes if needed

The helpers will automatically merge everything together.