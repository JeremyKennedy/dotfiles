# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a NixOS/home-manager dotfiles repository using Nix flakes. The configuration is split between system-level (NixOS) and user-level (home-manager) configurations.

### Key Structure

- `nix/flake.nix` - Main flake configuration defining all NixOS hosts (desktop, bee, halo, pi)
- `nix/hosts/` - Host-specific configurations
  - `navi/` - Desktop workstation (hostname: JeremyDesktop)
  - `bee/` - DNS and network services server (192.168.1.245)
  - `halo/` - VPS with monitoring services (46.62.144.212)
  - `pi/` - Raspberry Pi configuration (192.168.1.230)
- `nix/modules/` - Reusable NixOS modules
  - `core/` - Modules used by ALL hosts (includes base, boot, networking, security, ssh, tailscale, performance, hardware, shell, git)
  - `desktop/` - Desktop/GUI modules (hyprland, graphics, audio)
  - `services/` - Service modules (dns/, web/, monitoring/)
  - `home/` - Home-manager modules (terminal, editors, browsers)
- `nix/profiles/` - Composition profiles (server.nix, desktop.nix)
- `nix/nixos/` - Legacy desktop configuration (being migrated)
- `nix/home-manager/` - User-level home-manager configuration modules
- `nix/overlays/` - Package overlays for stable/unstable/master nixpkgs
- `nix/pkgs/` - Custom package definitions
- `nix/secrets.json` - Secrets file (referenced in flake)
- `hypr/` - Hyprland window manager configuration
- `scripts/` - Standalone shell scripts

### Configuration Organization

**NixOS modules** (system-wide):
- `configuration.nix` - Main system configuration
- `hyprland.nix` - Hyprland window manager setup
- `graphics.nix` - GPU and graphics configuration
- `network.nix` - Network and firewall settings
- `scripts.nix` - Custom scripts and systemd services
- `waybar.nix` - Status bar configuration
- `filesystems.nix` - Filesystem mounts and configuration
- `ledger.nix` - Ledger-specific configuration
- `programs.nix` - System-level program installations
- `shell.nix` - System-level shell configuration
- `hardware-configuration.nix` - Hardware-specific configuration

**Home-manager modules** (user-specific):
- `home.nix` - Main user configuration
- `packages.nix` - User package definitions
- `programs.nix` - Program-specific configurations (Git, Ripgrep, Tmux, etc.)
- `services.nix` - User services
- `shell.nix` - Shell configuration (Fish shell, Starship prompt, Alacritty terminal)
- `chatgpt-cli.nix` - ChatGPT CLI configuration
- `hass-cli.nix` - Home Assistant CLI configuration

**Hyprland Configuration Files** (in `hypr/.config/hypr/`):
- `hyprland.conf` - Main Hyprland window manager configuration
- `hypridle.conf` - Idle management configuration
- `hyprlock.conf` - Screen lock configuration

**Key Programs Configured**:
- **Shell**: Fish shell with custom abbreviations and z plugin
- **Prompt**: Starship prompt
- **Terminal**: Alacritty
- **Editor**: Neovim (with vi/vim aliases)
- **File utilities**: eza (ls replacement), fzf, ripgrep, broot, nnn
- **Development**: Git (with delta diff viewer), direnv, tmux, GitHub CLI
- **System monitoring**: btop

## Common Commands

The repository includes a `justfile` that provides convenient commands for common operations. Run `just` to see all available commands.

### System Management

#### Local Desktop Rebuild
```bash
# Rebuild local desktop
cd /home/jeremy/dotfiles/nix
just rebuild
```

#### Remote Deployment
```bash
cd /home/jeremy/dotfiles/nix

# Deploy to specific hosts
just deploy bee                  # Deploy to single host
just deploy halo                 # Deploy to another host

# Deploy to all hosts
just deploy-all

# Check deployment status
just status

# Show what would change before deploying
just diff bee

# Alternative: Use direct deploy when colmena fails
just deploy-direct halo 46.62.144.212
just deploy-direct bee 192.168.1.245
```

#### Other Commands
```bash
# Update flake inputs (packages)
just update

# Format nix files
just fmt

# Check flake configuration
just check
just check-host bee              # Check specific host

# Build a host configuration without deploying
just build bee

# SSH to a host
just ssh bee

# Run garbage collection on a host
just gc halo

# Show system info for all hosts
just info

# Check system logs (still requires direct command)
sudo journalctl -u <service-name>

# Manage systemd services (still requires direct commands)
sudo systemctl status <service-name>
sudo systemctl restart <service-name>
```

**Note**: The system is configured to allow password-less sudo access for `nixos-rebuild`, `journalctl`, and `systemctl` commands, enabling Claude Code to run these administrative commands directly.

**IMPORTANT**: When adding new files to this repository, they must be git-added before attempting a rebuild. NixOS flakes only include tracked files, so untracked files will cause build failures.

```bash
# Add new files before rebuilding
cd /home/jeremy/dotfiles/nix
git add .
just rebuild
```

### Development
```bash
cd /home/jeremy/dotfiles/nix

# Enter development shell with nix tools available
nix develop

# Build specific package from pkgs/
nix build .#<package-name>

# Enter host-specific nix shell
just shell bee
```

### Custom Services

The system includes custom systemd services defined in `scripts.nix`:

**MQTT Volume Control** (`mqtt-service`):
- Runs as systemd service under user "jeremy"
- Connects to MQTT broker at 192.168.1.240
- Controls system volume via wpctl based on MQTT messages
- Script located at `/etc/mqtt-service/main.py`

**Grist Payment Updater** (`grist-payment-updater`):
- Daily systemd timer service at exactly 8:00 AM
- Runs as dedicated `grist-updater` system user
- Updates payment due dates in Grist spreadsheet based on recurrence patterns
- Environment configuration in `/etc/grist-payment-updater/env`

### Writing Custom Services

All services in this repository use a modular approach. Each service has its own subdirectory under `scripts/` with a `service.nix` file:

**Service Structure**:
```
nix/nixos/scripts/
├── scripts.nix              # Imports all service modules
├── mqtt-service/
│   ├── service.nix          # Service definition
│   ├── main.py              # Python script
│   └── CLAUDE.md            # Service documentation
└── grist-payment-updater/
    ├── service.nix          # Service definition  
    ├── main.py              # Python script
    └── CLAUDE.md            # Service documentation
```

**Service Template** (`scripts/my-service/service.nix`):
```nix
{ config, lib, pkgs, ... }:

let
  python = pkgs.python3.withPackages (ps: with ps; [required-packages]);
in
{
  # Deploy script to /etc/
  environment.etc."my-service/main.py".source = ./main.py;
  environment.etc."my-service/main.py".mode = "0755";
  
  systemd.services.my-service = {
    enable = true;
    description = "My custom service";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];  # or omit for timer-only services
    serviceConfig = {
      User = "jeremy";  # or dedicated user
      ExecStart = "${python}/bin/python3 /etc/my-service/main.py";
      Restart = "always";  # or "no" for oneshot
    };
  };
}
```

**Adding to System** (`scripts.nix`):
```nix
{
  imports = [
    ./scripts/mqtt-service/service.nix
    ./scripts/grist-payment-updater/service.nix
    ./scripts/my-service/service.nix  # Add new service here
  ];
}
```

3. **Service Patterns**:
   - **Always-running services**: Use `Restart = "always"` with `wantedBy = ["multi-user.target"]`
   - **Scheduled tasks**: Use `systemd.timers` with `Type = "oneshot"`
   - **Python services**: Use `pkgs.python3.withPackages` and deploy scripts via `environment.etc`
   - **User services**: Set appropriate `User` and environment variables
   - **System users**: Create dedicated users with `users.users.service-name`
   - **File permissions**: Use `systemd.tmpfiles.rules` for directories/files

**IMPORTANT**: Always `git add` new service files before rebuilding, as NixOS flakes only include tracked files.

### Package Management

The configuration uses multiple nixpkgs channels:
- `nixpkgs` (unstable) - Primary package source
- `nixpkgs-stable` - Stable packages (accessible as `pkgs.stable`)
- `nixpkgs-unstable` - Unstable packages (accessible as `pkgs.unstable`)
- `nixpkgs-master` - Master branch packages (accessible as `pkgs.master`)

Custom overlays provide access to different package versions and custom packages from the `pkgs/` directory.

### Multi-Host Homelab Configuration

This repository now supports multiple NixOS hosts as part of a homelab deployment:

**Hosts**:
- `JeremyDesktop` - Main desktop workstation (x86_64) - *directory: /hosts/navi/*
- `bee` - Mini PC for DNS/network services (x86_64)  
- `halo` - Hetzner VPS for remote services (x86_64)
- `pi` - Raspberry Pi (aarch64)

**Module Organization**:
- **Core** (`/modules/core/`) - Used by ALL hosts
- **System** (`/modules/system/`) - Optional system features
- **Desktop** (`/modules/desktop/`) - GUI/desktop modules
- **Services** (`/modules/services/`) - Service configurations
- **User** (`/modules/user/`) - User-level configurations
- **Home** (`/modules/home/`) - Home-manager modules
- **Profiles** (`/profiles/`) - Common host type configurations

**Deployment Commands**:
```bash
# Deploy to a specific host using Colmena
just deploy bee
just deploy halo

# Deploy to all hosts
just deploy-all

# Check host status
just status

# Initial deployment with nixos-anywhere (for new hosts)
nix run github:nix-community/nixos-anywhere -- --flake .#bee root@<ip-address>
```

**DNS and Network Services** (on bee):
- **CoreDNS**: Primary DNS server handling .home domains and forwarding
- **AdGuard Home**: DNS filtering and ad blocking (upstream for CoreDNS)
- **Traefik**: Reverse proxy for internal services with automatic HTTPS

All services are configured for Tailscale-only access by default, ensuring security through the VPN layer. The .home domain is used for internal services, with Traefik providing unified ingress.

### Best Practices

- After making changes, always rebuild, commit, push, and check git status to ensure completion.
```
