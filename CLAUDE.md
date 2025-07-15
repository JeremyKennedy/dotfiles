# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a NixOS/home-manager dotfiles repository using Nix flakes. The configuration is split between system-level (NixOS) and user-level (home-manager) configurations.

### Key Structure

- `flake.nix` - Main flake configuration defining all NixOS hosts (navi, bee, halo, pi)
- `hosts/` - Host-specific configurations
  - `navi/` - Desktop workstation (192.168.1.250)
  - `bee/` - DNS and network services server (192.168.1.245)
  - `halo/` - VPS with monitoring services (46.62.144.212)
  - `pi/` - Raspberry Pi configuration (192.168.1.230)
- `modules/` - Reusable NixOS modules
  - `core/` - Modules used by ALL hosts (includes base, boot, networking, security, ssh, tailscale, performance, hardware, shell, git, hosts.nix)
  - `desktop/` - Desktop/GUI modules (hyprland, graphics, audio)
  - `services/` - Service modules (network/, web/, monitoring/, utility/)
  - `system/` - Optional system modules (debug-tools.nix)
- `profiles/` - Composition profiles (server.nix, desktop.nix)
- `home-manager/` - User-level home-manager configuration modules
- `overlays/` - Package overlays for stable/unstable/master nixpkgs
- `secrets.json` - Secrets file (referenced in flake)
- `scripts/` - Deployment and utility scripts (deploy-host.sh, homelab-test/)
- `docs/` - Documentation (architecture, deployment, networking, services, troubleshooting)

### Configuration Organization

**NixOS modules** (system-wide):
- `configuration.nix` - Main system configuration
- `hyprland.nix` - Hyprland window manager setup
- `graphics.nix` - GPU and graphics configuration
- `network.nix` - Network and firewall settings
- `services.nix` - Custom services and systemd units
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

**Hyprland Configuration Files** (in `modules/desktop/hyprland/configs/`):
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

## NixOS Debugging References

When implementing new features or debugging issues:

1. **Search GitHub for Real Examples**:
   ```
   site:github.com "services.SERVICE_NAME" language:nix
   site:github.com "MODULE_NAME" "nixos" language:nix
   ```

2. **Official References**:
   - **NixOS Options Search**: https://mynixos.com/options/
   - **Nixpkgs Source**: https://github.com/NixOS/nixpkgs/tree/master/nixos/modules
   - **NixOS Wiki**: https://wiki.nixos.org/
   - **NixOS Tests**: https://github.com/NixOS/nixpkgs/tree/master/nixos/tests

3. **Common Debugging**:
   ```bash
   # Check service logs
   ssh root@HOST.sole-bigeye.ts.net "journalctl -u SERVICE -f"
   
   # Test with curl
   curl -I https://SERVICE.DOMAIN --resolve SERVICE.DOMAIN:443:IP_ADDRESS
   
   # Check Nix evaluation
   nix eval .#nixosConfigurations.HOST.config.services.SERVICE --json | jq
   ```

## Service Configuration

**Traefik Services** are organized in `/modules/services/network/traefik/services/`:
- `media.nix` - Plex, *arr stack, media management
- `productivity.nix` - Nextcloud, Gitea, document management
- `monitoring.nix` - Grafana, Uptime Kuma, metrics
- `network.nix` - Network tools and utilities
- `gaming.nix` - Game servers
- `webhost.nix` - Web hosting tools

Services are defined as either `public` (accessible from internet) or `tailscale` (VPN only).

## Common Commands

The repository includes a `justfile` that provides convenient commands for common operations. Run `just` to see all available commands.

**Note**: The `just` command is automatically available when you `cd` into the nix directory (via direnv). If direnv is not set up, you can manually enter the shell with `nix develop`.

### System Management

#### Local Desktop Rebuild
```bash
# Rebuild local desktop
cd /home/jeremy/dotfiles
just rebuild
```

#### Remote Deployment
```bash
cd /home/jeremy/dotfiles

# Deploy to specific hosts
just deploy bee                  # Deploy to single host
just deploy bee halo             # Deploy to multiple hosts
just deploy bee halo pi          # Deploy to any combination

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

**Deployment Notes**:
- All hosts require Tailscale access (`.sole-bigeye.ts.net` domain)
- `deploy-direct` still needs firewall access - won't bypass Tailscale-only restrictions
- **Locked out?** Hetzner: disable firewall via console; Local: JetKVM (movable between bee/pi)
- After network changes: wait 2-3 min, deployment may have succeeded but disconnected

#### Other Commands
```bash
# Update flake inputs (packages)
just update

# Format nix files
just fmt

# Check flake configuration
just check                       # Check all hosts
just check bee                   # Check specific host

# Build a host configuration without deploying
just build bee

# Test services on all hosts
just test-services               # Check all services are running

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
cd /home/jeremy/dotfiles
git add .
just rebuild
```

## SSH Access to Hosts

For SSH access to remote hosts in the homelab:
- **Username**: `root` for all external hosts (tower, bee, halo, pi)
- **Authentication**: Uses SSH keys configured in the homelab

Example SSH commands:
```bash
ssh root@192.168.1.240  # Tower (Unraid)
ssh root@100.74.102.74  # Bee via Tailscale
ssh root@46.62.144.212  # Halo (VPS)
```

## Security Considerations

**This repository is intended to be published publicly.** All configurations must be secure even with full public knowledge:

- **No secrets in code**: All sensitive data uses age-encrypted secrets or environment files
- **No hardcoded IPs**: Internal IPs (192.168.x.x) and Tailscale IPs are not sensitive
- **No security through obscurity**: Security relies on proper authentication, not hidden URLs
- **Safe service exposure**: Services use Tailscale-only access or proper authentication
- **Domain strategy**: Internal services on .home.jeremyk.net are DNS-blocked externally

When adding new services or configurations:
1. Never commit passwords, API keys, or tokens (use secrets.nix and age encryption)
2. Ensure all internal services are behind Tailscale middleware
3. Document all access methods openly - security comes from authentication, not secrecy
4. Use standard ports and practices - no security through obscurity

### Development
```bash
cd /home/jeremy/dotfiles

# Enter development shell with nix tools available
nix develop

# Build specific package from pkgs/
nix build .#<package-name>

# Enter host-specific nix shell
just shell bee
```

### Custom Services

The system includes custom systemd services defined in `services.nix`:

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

All services in this repository use a modular approach. Each service has its own subdirectory under `hosts/navi/services/` with a `service.nix` file:

**Service Structure**:
```
hosts/navi/services/
├── mqtt-service/
│   ├── service.nix          # Service definition
│   ├── main.py              # Python script
│   └── CLAUDE.md            # Service documentation
└── grist-payment-updater/
    ├── service.nix          # Service definition  
    ├── main.py              # Python script
    └── CLAUDE.md            # Service documentation
```

**Service Template** (`hosts/navi/services/my-service/service.nix`):
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

**Adding to System** (`hosts/navi/services.nix`):
```nix
{
  imports = [
    ./services/mqtt-service/service.nix
    ./services/grist-payment-updater/service.nix
    ./services/my-service/service.nix  # Add new service here
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
- **AdGuard Home**: DNS filtering, ad blocking, and .home.jeremyk.net domain resolution via DNS rewrites
- **Traefik**: Reverse proxy for internal services with automatic HTTPS

All services are configured for Tailscale-only access by default, ensuring security through the VPN layer. The .home domain is used for internal services, with Traefik providing unified ingress.

### Best Practices

- After making changes, always rebuild, commit, push, and check git status to ensure completion.
```
