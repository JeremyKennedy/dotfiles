# Module System Guide

## Overview

The configuration uses a modular NixOS structure for reusability and organization.

## Module Categories

### Core Modules (`/modules/core/`)

Applied to ALL hosts automatically via profiles:

- `base.nix` - Nix settings, timezone, basic packages
- `boot.nix` - Boot loader configuration
- `git.nix` - Git configuration
- `hardware.nix` - Hardware optimization
- `hosts.nix` - Centralized host definitions
- `networking.nix` - Network configuration
- `performance.nix` - System optimizations
- `security.nix` - Firewall, fail2ban
- `shell.nix` - Fish shell, starship prompt
- `ssh.nix` - SSH server configuration
- `tailscale.nix` - Tailscale VPN

### Desktop Modules (`/modules/desktop/`)

For GUI systems:

- `applications.nix` - Desktop applications
- `development.nix` - Development tools
- `fonts.nix` - System fonts
- `gaming.nix` - Gaming tools
- `graphics.nix` - GPU configuration
- `hyprland.nix` - Window manager
- `terminal.nix` - Terminal emulator
- `users.nix` - User accounts
- `waybar.nix` - Status bar
- `wayland.nix` - Wayland environment

### Service Modules (`/modules/services/`)

Optional services:

- `monitoring/` - Netdata, Uptime Kuma
- `network/` - AdGuard, Traefik
- `utility/` - Custom services
- `web/` - Web hosting

### System Modules (`/modules/system/`)

Optional system features:

- `debug-tools.nix` - Network debugging tools

## Using Modules

### In Host Configuration

```nix
# hosts/hostname/default.nix
{
  imports = [
    ../../profiles/server.nix      # Includes all core modules
    ../../modules/services/network/adguard.nix
    ../../modules/system/debug-tools.nix
  ];
}
```

### In Profiles

```nix
# profiles/server.nix
{
  imports = [
    ../modules/core  # Import entire directory
  ];
}
```

## Creating a Module

Basic structure:

```nix
# modules/category/mymodule.nix
{ config, lib, pkgs, ... }:
{
  # Options definition (optional)
  options.services.myservice = {
    enable = lib.mkEnableOption "my service";
  };

  # Configuration
  config = lib.mkIf config.services.myservice.enable {
    systemd.services.myservice = {
      # Service definition
    };
  };
}
```

## Module Best Practices

1. **Single Responsibility** - Each module should do one thing
2. **Configurable** - Use options for flexibility
3. **Dependencies** - Import required modules explicitly
4. **Documentation** - Add comments explaining purpose
5. **Validation** - Test module builds in isolation

## Real Examples

- **Service modules**: See `/modules/services/network/traefik/services/` for service definitions
- **Core modules**: See `/modules/core/` for system-wide configurations
- **Host configs**: See `/hosts/*/default.nix` for how modules are composed

## Related Documentation

- [Architecture Overview](./architecture.md) - System design and module usage
- [Services Catalog](./services.md) - Service module examples
- [Deployment Guide](./deployment.md) - Deploying module changes
- [Troubleshooting](./troubleshooting.md) - Module-related issues
