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
```

### Development
```bash
# Enter development shell with nix tools available
nix develop /home/jeremy/dotfiles/nix

# Build specific package from pkgs/
nix build /home/jeremy/dotfiles/nix#<package-name>
```

### Custom Services

The system includes a custom MQTT volume control service (`mqtt-volume`) defined in `scripts.nix` that:
- Runs as systemd service under user "jeremy"
- Connects to MQTT broker at 192.168.1.240
- Controls system volume via wpctl based on MQTT messages
- Script located at `/etc/mqtt-volume/mqtt_volume.py`

### Package Management

The configuration uses multiple nixpkgs channels:
- `nixpkgs` (unstable) - Primary package source
- `nixpkgs-stable` - Stable packages (accessible as `pkgs.stable`)
- `nixpkgs-unstable` - Unstable packages (accessible as `pkgs.unstable`)
- `nixpkgs-master` - Master branch packages (accessible as `pkgs.master`)

Custom overlays provide access to different package versions and custom packages from the `pkgs/` directory.