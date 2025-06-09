# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Architecture

This is a NixOS/home-manager dotfiles repository using Nix flakes. The configuration is split between system-level (NixOS) and user-level (home-manager) configurations.

### Key Structure

- `nix/flake.nix` - Main flake configuration defining the NixOS system "JeremyDesktop"
- `nix/nixos/` - System-level NixOS configuration modules
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

**Home-manager modules** (user-specific):
- `home.nix` - Main user configuration
- `packages.nix` - User package definitions
- `programs.nix` - Program-specific configurations
- `services.nix` - User services
- `shell.nix` - Shell configuration

## Common Commands

### System Management
```bash
# Rebuild and switch system configuration
sudo nixos-rebuild switch --flake /home/jeremy/dotfiles/nix#JeremyDesktop

# Update flake inputs (packages)
nix flake update /home/jeremy/dotfiles/nix

# Format nix files
nix fmt /home/jeremy/dotfiles/nix

# Check system logs
sudo journalctl -u <service-name>

# Manage systemd services
sudo systemctl status <service-name>
sudo systemctl restart <service-name>
```

**Note**: The system is configured to allow password-less sudo access for `nixos-rebuild`, `journalctl`, and `systemctl` commands, enabling Claude Code to run these administrative commands directly.

**IMPORTANT**: When adding new files to this repository, they must be git-added before attempting a rebuild. NixOS flakes only include tracked files, so untracked files will cause build failures.

```bash
# Add new files before rebuilding
git add .
sudo nixos-rebuild switch --flake /home/jeremy/dotfiles/nix#JeremyDesktop
```

### Development
```bash
# Enter development shell with nix tools available
nix develop /home/jeremy/dotfiles/nix

# Build specific package from pkgs/
nix build /home/jeremy/dotfiles/nix#<package-name>
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

### Best Practices

- After making changes, always rebuild, commit, push, and check git status to ensure completion.
```
