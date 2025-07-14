# DNS Architecture

## Overview

The homelab DNS infrastructure has been updated to provide better client visibility and declarative configuration.

## Current Architecture

### Primary DNS: AdGuard Home (Port 53)
- **Role**: Primary DNS server with filtering and ad-blocking
- **Port**: 53 (standard DNS port)
- **Web UI**: Port 3000 (Tailscale access only)
- **Configuration**: Fully declarative with `mutableSettings = false`
- **Key Feature**: Shows real client IP addresses in dashboard

### Backup DNS: CoreDNS (Port 5354)
- **Role**: Secondary DNS server for special cases
- **Port**: 5354 (non-standard port)
- **Purpose**: Fallback option if AdGuard configuration needs adjustment
- **Features**: Handles .home and .home.jeremyk.net domains via template plugin

## Configuration Details

### AdGuard Wildcard DNS
DNS rewrites are configured under `settings.filtering.rewrites`:

```nix
filtering = {
  rewrites = [
    {
      domain = "*.home";
      answer = "100.74.102.74";
    }
    {
      domain = "*.home.jeremyk.net";
      answer = "100.74.102.74";
    }
  ];
};
```

### Why This Architecture?

1. **Client IP Visibility**: Direct connections to AdGuard show real client IPs
2. **Declarative Config**: NixOS manages all DNS settings declaratively
3. **Redundancy**: CoreDNS available as backup on port 5354
4. **Wildcard Support**: Both services handle wildcard domains properly

## Access Methods

- **AdGuard Web UI**: 
  - http://adguard.home
  - https://adguard.home.jeremyk.net
  - http://100.74.102.74:3000

- **DNS Queries**:
  - Primary: `dig @100.74.102.74 example.com` (port 53)
  - Backup: `dig @100.74.102.74 -p 5354 example.com`

## Testing

```bash
# Test wildcard resolution
dig @100.74.102.74 test.home
dig @100.74.102.74 app.home.jeremyk.net

# Check AdGuard dashboard for client IPs
# Visit http://adguard.home → Query Log
```