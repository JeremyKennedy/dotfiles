# NixOS Multi-Host Homelab Deployment Plan

## Overview

This plan outlines the phased approach to refactor the existing single-host NixOS configuration into a multi-host setup supporting `jeremydesktop`, `bee`, `halo`, and `pi` hosts. The approach prioritizes maintaining desktop functionality while enabling declarative infrastructure management via Colmena.

## Current Implementation Status

### ✅ What's Been Done
- **Multi-host flake structure** - All 4 hosts defined with proper architecture support
- **Colmena deployment** - Ready for remote deployments (no buildOnTarget)
- **Common modules** - base, boot, performance, shell, git, ssh, tailscale, hardware, security, networking
- **Service modules** - Created `/modules/` directory for service-specific modules
- **Host configurations** - All hosts have basic configs with disko where needed
- **Development environment** - devShell with colmena, nixos-anywhere, disko, just
- **Baseline tracking** - Comprehensive system to ensure desktop remains unchanged
- **Deployment scripts** - Both initial deployment and update scripts ready
- **Claude Code** - Added to all hosts via common/base.nix
- **Initial deployments** - halo and bee successfully deployed and running
- **Security** - Common fail2ban module added to all hosts
- **Uptime Kuma** - Configured on halo (accessible via Tailscale)
- **DNS/Network modules** - AdGuard, CoreDNS, and Traefik modules created and deployed
- **DNS Infrastructure** - CoreDNS handling .home domains, AdGuard for filtering
- **.home Domain Resolution** - Working correctly after fixing CoreDNS hosts plugin
- **Desktop DNS** - Updated to use bee as primary DNS server

### 🔄 Current Focus
- **Phase 6** - Full Deployment and Validation (DNS services deployed and working!)

### 📝 Recent Accomplishments
- **DNS Services Deployed** - AdGuard Home (primary DNS) and CoreDNS (backup) running on bee
- **DNS Architecture Updated** - AdGuard on port 53, CoreDNS on port 5354
- **Client IP Visibility** - Fixed! AdGuard now shows real client IPs instead of localhost
- **Wildcard DNS** - Declaratively configured for *.home and *.home.jeremyk.net domains
- **Desktop DNS Updated** - Desktop now uses bee as primary DNS server
- **Services Accessible** - AdGuard (port 3000), Traefik dashboard (port 9090)

### 📝 Future Tasks
1. **Phase 4** - Consolidate desktop config to use common modules (postponed)
2. **Phase 7** - Ingress for Unraid Services (Bridge Mode)
3. **Monitoring & Backups** - To be added after core services are working
4. **Pi deployment** - After DNS services are moved to bee

## Task Completion Tracking

**Overall Progress**: ⏳ In Progress (5.5/10 phases complete)

### Phase Status
- [x] **Phase 1**: Refactor for Multi-Host (Desktop Unchanged) - 6/6 tasks ✅
- [x] **Phase 2**: Add Server Hosts Configuration - 7/7 tasks ✅
- [x] **Phase 2.5**: Early Bee Deployment (Barebones) - 5/5 tasks ✅
- [x] **Phase 3**: Extract and Share Common Configuration - 6/6 tasks ✅
- [ ] **Phase 4**: Move Home-Manager Programs to System Level - 0/6 tasks (POSTPONED)
- [x] **Phase 5**: DNS and Ingress Infrastructure - 7/7 tasks ✅ COMPLETE
- [ ] **Phase 6**: Full Deployment and Validation - 6/8 tasks (DNS deployed & working!)
- [ ] **Phase 7**: Ingress for Unraid Services (Bridge Mode) - 0/6 tasks
- [ ] **Phase 8**: Secure Routing Boundaries - 1/5 tasks (security module done)
- [ ] **Phase 9**: Observability and Health - 0/4 tasks
- [ ] **Phase 10**: DNS/Ingress Debug & Testing Utilities - 0/3 tasks

### Quick Reference - Current Task
**Current**: Phase 6 - Testing and validating DNS infrastructure on bee
**Last Update**: DNS architecture refactored - AdGuard primary (port 53), CoreDNS backup (port 5354), client IPs now visible

### Baseline Capture and Validation

**Before ANY changes:**
```bash
# Capture initial baseline (run from nix directory)
./baselines/capture-baseline.sh initial
```

**After EACH phase:**
```bash
# Compare current state with baseline (READ-ONLY, no system changes)
./baselines/compare-baseline.sh

# Additional validation commands (all READ-ONLY)
nix flake check
sudo nixos-rebuild dry-build --flake .#navi
```

**IMPORTANT**: All baseline and validation commands are READ-ONLY. They will:
- ✅ Build configurations in the Nix store
- ✅ Compare with baseline
- ❌ NEVER run `nixos-rebuild switch`
- ❌ NEVER modify the running system

### Baseline Structure (Streamlined)
All baseline files are stored in `nix/baselines/` (gitignored):

**Key Principle**: The system derivation path is the single source of truth. If it doesn't change, nothing functionally changed.

- `initial/` - Baseline before changes (only 4 files):
  - `system-derivation.txt` - **PRIMARY**: The exact store path (if this matches, config is unchanged)
  - `system-closure.txt` - Package list for diff analysis only
  - `critical-values.txt` - Quick sanity checks (hostname, stateVersion, package count)
  - `SUMMARY.txt` - Human-readable summary
- `current/` - Created only when changes detected
- `capture-baseline.sh` - Focused capture (usage: `./capture-baseline.sh [initial|current]`)
- `compare-baseline.sh` - One-line answer: changed or unchanged (READ-ONLY)

## Key Requirements

- **Secrets**: Already handled via agenix (no setup needed)
- **Build Strategy**: All builds happen on `jeremydesktop` (no `buildOnTarget`)
- **Networking**: Tailscale routing enabled on all hosts
- **Firewall**: Hetzner firewall handles `halo`, minimal NixOS firewall
- **Deployment**: SSH over WAN initially, Tailscale later
- **Security**: Uptime Kuma not publicly exposed
- **Dev Environment**: Using Nix devShells (not devenv)

## Secrets Management with Agenix

### Adding New Hosts to Secrets
When deploying a new host, you must add its SSH host key to enable secret decryption:

```bash
# 1. Get the host's SSH public key
ssh root@<host-ip> 'cat /etc/ssh/ssh_host_ed25519_key.pub'

# 2. Add to secrets.nix
# Example: bee = "ssh-ed25519 AAAAC3Nza... root@bee";

# 3. Add host to allSystems list
# allSystems = [ jeremyDesktop bee ];

# 4. Re-encrypt all secrets
cd /home/jeremy/dotfiles/nix
agenix --rekey

# 5. Commit and push changes
git add secrets.nix secrets/
git commit -m "Add bee host key for secrets"
git push
```

### Common Agenix Commands
```bash
# Edit a secret
agenix -e secrets/hass_token.age

# Create new secret
agenix -e secrets/new_secret.age

# Re-encrypt all secrets (after adding/removing keys)
agenix --rekey

# List all secrets
ls -la secrets/*.age
```

## Tailscale Configuration

### Post-Deployment Tailscale Setup
```bash
# Join network (interactive - will provide auth URL)
ssh root@<host-ip> 'tailscale up'

# Enable SSH over Tailscale (port 22 not required)
ssh root@<host-ip> 'tailscale set --ssh'

# Configure as exit node (for VPS hosts like halo)
ssh root@<host-ip> 'tailscale set --advertise-exit-node'

# Check status
ssh root@<host-ip> 'tailscale status'
```

## Desktop Configuration Note

**IMPORTANT**: The desktop hostname must remain `JeremyDesktop` in flake.nix for now.
- The host directory is `/hosts/navi/` for organization
- But the NixOS configuration name remains `JeremyDesktop`
- The hostname will be updated to match the directory name in the future

**Current usage**:
```bash
# Rebuild desktop
sudo nixos-rebuild switch --flake .#JeremyDesktop

# Deploy with colmena
colmena apply --on JeremyDesktop
```

**Future rename to navi**:
1. Update hostname in flake.nix (`JeremyDesktop` → `navi`)
2. Update `networking.hostName` in the config
3. Update colmena deployment keys
4. Update any secrets/documentation
5. Reboot and re-apply config

## Current State Analysis

### Existing Configuration Structure
- **Desktop**: Single host `JeremyDesktop` in `/home/jeremy/dotfiles/nix/`
- **Current flake**: Has agenix already integrated
- **Existing hetz-nix**: Separate directory with VPS config for halo
- **Home-manager**: Heavy usage for shell and programs (needs migration)

### Key Files to Preserve
- `nix/nixos/configuration.nix` - Main desktop config (DO NOT CHANGE until Phase 4)
- `nix/home-manager/` - User configs (will be reduced in scope)
- `nix/secrets.json` - Already exists
- `hetz-nix/` - Reference for halo configuration

### Critical Constraints
1. **Desktop must work identically** until Phase 4
2. **No buildOnTarget** - all ARM/x86 builds on desktop
3. **SSH access required** - use existing SSH key for all hosts
4. **Tailscale routing** - all hosts become routers/relays

## Phase 1: Refactor for Multi-Host (Desktop Unchanged)

**Status**: ✅ Complete

### Task List - Phase 1
- [x] **1.1**: Create directory structure (`hosts/` with subdirectories) ✅
- [x] **1.2**: Update flake.nix with multi-host support and colmena ✅
- [x] **1.3**: Create desktop wrapper (`hosts/jeremydesktop/default.nix`) ✅
- [x] **1.4**: Create development environment (devShell in flake.nix, `.envrc`) ✅
- [x] **1.5**: Run comprehensive desktop validation ✅
- [x] **1.6**: Verify all configs build (`nix flake check`) ✅

### 1.1 Create Directory Structure

```
nix/
├── hosts/                   # Host-specific configurations
│   ├── navi/                # Desktop workstation (hostname: JeremyDesktop)
│   │   └── default.nix      # Wrapper for existing config
│   ├── bee/
│   │   ├── default.nix
│   │   ├── disko.nix
│   │   └── hardware-configuration.nix
│   ├── halo/
│   │   ├── default.nix
│   │   ├── disko.nix
│   │   └── hardware-configuration.nix
│   └── pi/
│       └── default.nix
├── modules/                 # All reusable modules
│   ├── core/                # Modules for ALL hosts
│   │   ├── base.nix         # Core nix settings, basic packages
│   │   ├── boot.nix         # Boot configuration
│   │   ├── networking.nix   # Basic network config
│   │   ├── performance.nix  # Performance optimizations
│   │   ├── shell.nix        # Fish, starship, shell utilities
│   │   ├── git.nix          # Git configuration
│   │   ├── ssh.nix          # SSH configuration
│   │   ├── tailscale.nix    # Tailscale with routing
│   │   ├── hardware.nix     # Hardware configuration
│   │   └── security.nix     # Security (fail2ban, firewall)
│   ├── system/              # Optional system modules
│   ├── desktop/             # Desktop/GUI modules
│   ├── services/            # Service modules
│   │   ├── dns/
│   │   │   ├── adguard.nix
│   │   │   └── coredns.nix
│   │   ├── web/
│   │   │   └── traefik.nix
│   │   └── monitoring/
│   │       └── uptime-kuma.nix
│   ├── user/                # User-level modules
│   └── home/                # Home-manager modules
├── profiles/                # Host type compositions
│   ├── server.nix
│   └── desktop.nix
└── flake.nix                # Main flake configuration
```

### 1.2 Update flake.nix

```nix
{
  description = "Multi-host NixOS configuration";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";  # For bleeding-edge Traefik, Tailscale
    
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    colmena = {
      url = "github:zhaofengli/colmena";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  
  outputs = { self, nixpkgs, ... }@inputs: let
    inherit (self) outputs;
    systems = ["x86_64-linux"];
    forAllSystems = nixpkgs.lib.genAttrs systems;
    secrets = builtins.fromJSON (builtins.readFile "${self}/secrets.json");
  in {
    # Existing outputs
    packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
    formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.alejandra);
    overlays = import ./overlays {inherit inputs;};
    
    # NixOS configurations
    nixosConfigurations = {
      jeremydesktop = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs secrets;};
        modules = [
          inputs.hyprland.nixosModules.default
          {programs.hyprland.enable = true;}
          inputs.agenix.nixosModules.default
          ./hosts/jeremydesktop/default.nix
        ];
      };
      
      bee = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs secrets;};
        modules = [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          ./hosts/bee/default.nix
        ];
      };
      
      halo = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs secrets;};
        modules = [
          inputs.agenix.nixosModules.default
          inputs.disko.nixosModules.disko
          ./hosts/halo/default.nix
        ];
      };
      
      pi = nixpkgs.lib.nixosSystem {
        system = "aarch64-linux";
        specialArgs = {inherit inputs outputs secrets;};
        modules = [
          inputs.agenix.nixosModules.default
          ./hosts/pi/default.nix
        ];
      };
    };
    
    # Colmena deployment
    colmena = {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        specialArgs = { inherit inputs outputs secrets; };
      };
      
      jeremydesktop = {
        deployment = {
          targetHost = "localhost";
          targetUser = "root";
          buildOnTarget = false;
        };
        imports = [ self.nixosConfigurations.jeremydesktop.config ];
      };
      
      bee = {
        deployment = {
          targetHost = "bee.example.com";  # Update with actual IP/hostname
          targetUser = "root";
          buildOnTarget = false;
        };
        imports = [ self.nixosConfigurations.bee.config ];
      };
      
      halo = {
        deployment = {
          targetHost = "halo.example.com";  # Update with actual IP/hostname
          targetUser = "root";
          buildOnTarget = false;
        };
        imports = [ self.nixosConfigurations.halo.config ];
      };
      
      pi = {
        deployment = {
          targetHost = "pi.example.com";  # Update with actual IP/hostname
          targetUser = "root";
          buildOnTarget = false;  # Build on desktop even for ARM
        };
        imports = [ self.nixosConfigurations.pi.config ];
      };
    };
  };
}
```

### 1.3 Create Desktop Wrapper

```nix
# hosts/jeremydesktop/default.nix
{ inputs, outputs, secrets, ... }: {
  imports = [ ../../nixos/configuration.nix ];
  # No changes - just wrapping existing config
}
```

### 1.4 Create Development Environment

```nix
# devenv.nix
{ pkgs, ... }: {
  packages = with pkgs; [
    colmena
    agenix
    nixos-anywhere
    disko
    git
    ssh-to-age
    nixpkgs-fmt
    alejandra
    nix-tree
    nix-diff
  ];
  
  pre-commit.hooks = {
    nixpkgs-fmt.enable = true;
  };
  
  enterShell = ''
    echo "🔧 NixOS Homelab Dev Environment"
    echo "📦 Available: colmena, agenix, nixos-anywhere, disko"
    echo "🎯 Hosts: jeremydesktop, bee, halo, pi"
  '';
}
```

```bash
# .envrc
use flake . --impure
```

### 1.5 Desktop Validation

**CRITICAL**: Desktop must remain functionally identical until Phase 4.

```bash
# Simply run the comparison script after each change
./baselines/compare-baseline.sh
```

This will show either:
- ✅ UNCHANGED - Desktop configuration is identical!
- ⚠️ CHANGED - Desktop configuration has been modified!

If changed, it will show:
- Exact package count differences
- Size changes in MB
- First 5 packages added/removed

**That's it!** The system derivation path tells us everything we need to know.

## Phase 2: Add Server Hosts Configuration

**Status**: ✅ Complete (7/7 tasks done)

### Task List - Phase 2
- [x] **2.1**: Create common modules (`base.nix`, `ssh.nix`, `tailscale.nix`) ✅
- [x] **2.2**: Configure halo (VPS) - port from `hetz-nix/` ✅
- [x] **2.3**: Configure bee (Mini PC) - minimal initial config ✅
- [x] **2.4**: Configure pi (Raspberry Pi) - placeholder ✅
- [x] **2.5**: Copy disko configs from `hetz-nix/` ✅ (halo has disko.nix)
- [x] **2.6**: Test all configs build without errors ✅
- [x] **2.7**: Verify desktop still unchanged ✅

### 2.1 Create Common Modules

```nix
# hosts/common/base.nix
{ pkgs, ... }: {
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    trusted-users = ["root"];
  };
  
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    jq
  ];
  
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";
}
```

```nix
# hosts/common/tailscale.nix
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";  # Enable routing on all hosts
  };
  
  networking.firewall.trustedInterfaces = ["tailscale0"];
}
```

```nix
# hosts/common/ssh.nix
{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7YCbzW2kMJxx2YIN2XLGpLZMNzcTjB6WWmvKPVjVnR"
  ];
}
```

### 2.2 Configure Halo (VPS)

```nix
# hosts/halo/default.nix
{ config, pkgs, lib, ... }: {
  imports = [
    ../common/base.nix
    ../common/ssh.nix
    ../common/tailscale.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];
  
  networking.hostName = "halo";
  
  # Boot configuration (from hetz-nix)
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  
  # Minimal firewall - Hetzner firewall handles main security
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    # Hetzner firewall allows SSH from home IP and Tailscale
  };
  
  # Enable IP forwarding for Tailscale exit node
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };
  
  # Uptime Kuma - NOT publicly exposed
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "127.0.0.1";  # Local only - access via Tailscale
      PORT = "3001";
    };
  };
  
  # Basic packages
  environment.systemPackages = with pkgs; [
    fish
    starship
  ];
  
  programs.fish.enable = true;
  programs.starship.enable = true;
  users.users.root.shell = pkgs.fish;
  
  # Maintenance
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "02:00";
    randomizedDelaySec = "45min";
  };
  
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  
  system.stateVersion = "24.05";
}
```

### 2.3 Configure Bee (Mini PC)

```nix
# hosts/bee/default.nix
{ config, pkgs, lib, ... }: {
  imports = [
    ../common/base.nix
    ../common/ssh.nix
    ../common/tailscale.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];
  
  networking.hostName = "bee";
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Basic shell setup
  programs.fish.enable = true;
  programs.starship.enable = true;
  users.defaultUserShell = pkgs.fish;
  
  system.stateVersion = "24.11";
}
```

```nix
# hosts/bee/disko.nix
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";  # Update based on actual hardware
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
```

### 2.4 Configure Pi (Placeholder)

```nix
# hosts/pi/default.nix
{ config, pkgs, lib, ... }: {
  imports = [
    ../common/base.nix
    ../common/ssh.nix
    ../common/tailscale.nix
  ];
  
  networking.hostName = "pi";
  
  # Raspberry Pi specific boot config would go here
  
  system.stateVersion = "24.11";
}
```

## Phase 2.5: Early Bee Deployment (Barebones)

**Status**: ⏸️ Not Started

**Purpose**: Deploy bee early with minimal config to establish working base before adding networking services.

### Task List - Phase 2.5
- [ ] **2.5.1**: Create barebones bee config (SSH + basic packages only)
- [ ] **2.5.2**: Generate hardware config for bee hardware
- [ ] **2.5.3**: Deploy bee with nixos-anywhere (barebones)
- [ ] **2.5.4**: Verify SSH access and basic functionality
- [ ] **2.5.5**: Test colmena deployment to bee

### 2.5.1 Barebones Bee Configuration

Create a minimal working configuration for bee:

```nix
# hosts/bee/barebones.nix - Temporary minimal config
{ config, pkgs, lib, ... }: {
  imports = [
    ./disko.nix
    ./hardware-configuration.nix
  ];
  
  # Basic system settings
  networking.hostName = "bee";
  time.timeZone = "America/Toronto";
  i18n.defaultLocale = "en_CA.UTF-8";
  
  # Boot configuration
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Enable flakes
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
  };
  
  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };
  
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7YCbzW2kMJxx2YIN2XLGpLZMNzcTjB6WWmvKPVjVnR"
  ];
  
  # Basic packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    htop
  ];
  
  # Minimal firewall
  networking.firewall.enable = true;
  
  system.stateVersion = "24.11";
}
```

### 2.5.2 Hardware Configuration

```bash
# Generate hardware config for bee (run this when bee hardware is available)
nixos-generate-config --show-hardware-config > hosts/bee/hardware-configuration.nix
```

### 2.5.3 Bee Disk Configuration (Simple)

```nix
# hosts/bee/disko.nix - Simple single disk layout
{
  disko.devices = {
    disk.main = {
      type = "disk";
      device = "/dev/sda";  # Update based on actual hardware
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
```

### 2.5.4 Update Flake for Barebones Bee

Temporarily point bee to barebones config:

```nix
# In flake.nix nixosConfigurations
bee = nixpkgs.lib.nixosSystem {
  specialArgs = {inherit inputs outputs secrets;};
  modules = [
    inputs.agenix.nixosModules.default
    inputs.disko.nixosModules.disko
    ./hosts/bee/barebones.nix  # Use barebones config initially
  ];
};
```

### 2.5.5 Deploy Barebones Bee

```bash
# Deploy bee with nixos-anywhere (barebones)
./deploy-host.sh bee root@192.168.1.245

# Or manually:
nix run github:nix-community/nixos-anywhere -- \
  --flake .#bee \
  root@192.168.1.245

# Post-deployment steps:
# 1. Get host SSH key for agenix
ssh root@192.168.1.245 'cat /etc/ssh/ssh_host_ed25519_key.pub'

# 2. Add the key to secrets.nix and update allSystems list
# 3. Re-encrypt all secrets
cd /home/jeremy/dotfiles/nix
agenix --rekey

# 4. Join Tailscale network
ssh root@192.168.1.245 'tailscale up'

# 5. Enable Tailscale SSH (optional - allows SSH via Tailscale without port 22)
ssh root@192.168.1.245 'tailscale set --ssh'

# 6. For exit node hosts (like halo), advertise exit node capability
ssh root@192.168.1.245 'tailscale set --advertise-exit-node'

# 7. Test colmena deployment
colmena apply --on bee
```

### 2.5.6 Validation

```bash
# Verify bee is reachable
colmena exec --on bee -- uname -a

# Check basic services
colmena exec --on bee -- systemctl status sshd
colmena exec --on bee -- systemctl status nix-daemon

# Verify basic packages available
colmena exec --on bee -- vim --version
colmena exec --on bee -- git --version
```

**Note**: After Phase 2.5 is complete, bee will have:
- Working SSH access
- Basic NixOS system
- Colmena deployment capability
- Ready for incremental service addition

Later phases will replace `barebones.nix` with the full `default.nix` configuration.

## Phase 3: Extract and Share Common Configuration

**Status**: ⏸️ Not Started

### Task List - Phase 3
- [ ] **3.1**: Create shared shell configuration (`common/shell.nix`)
- [ ] **3.2**: Create shared programs configuration (`common/programs.nix`)
- [ ] **3.3**: Update desktop to use common modules (incremental)
- [ ] **3.4**: Update server hosts to use common modules
- [ ] **3.5**: Test desktop still works after each common module addition
- [ ] **3.6**: Remove redundant config from existing files

### 3.1 Create Shared Shell Configuration

```nix
# hosts/common/shell.nix
{ pkgs, ... }: {
  programs.fish.enable = true;
  users.defaultUserShell = pkgs.fish;
  programs.starship.enable = true;
  
  programs.fish.interactiveShellInit = ''
    # Basic greeting
    function fish_greeting
      echo "🏠 "(hostname)" - "(date)
    end
    
    # Common aliases
    alias g='git'
    alias v='nvim'
    alias ll='eza -la'
    alias la='eza -la'
    alias tree='eza --tree'
  '';
  
  environment.systemPackages = with pkgs; [
    eza
    ripgrep
    fzf
    fd
    bat
    jq
    tree
  ];
}
```

### 3.2 Create Shared Programs Configuration

```nix
# hosts/common/programs.nix
{ pkgs, ... }: {
  programs.git = {
    enable = true;
    config = {
      user.name = "Jeremy Kennedy";
      user.email = "me@jeremyk.net";
      init.defaultBranch = "main";
      diff.tool = "delta";
      core.pager = "delta";
      interactive.diffFilter = "delta --color-only";
      delta.enable = true;
    };
  };
  
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };
  
  environment.systemPackages = with pkgs; [
    # From home-manager/programs.nix
    btop
    tmux
    nnn
    direnv
    gh
    broot
    delta
    
    # Additional useful tools
    ncdu
    duf
    procs
    sd
    dust
    bandwhich
  ];
  
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
```

### 3.3 Update Desktop to Use Common Modules

```nix
# hosts/jeremydesktop/default.nix
{ inputs, outputs, secrets, ... }: {
  imports = [
    ../common/base.nix
    ../common/shell.nix
    ../common/programs.nix
    ../common/ssh.nix
    ../common/tailscale.nix
    ../../nixos/configuration.nix
  ];
  
  # Desktop-specific overrides
  programs.fish.interactiveShellInit = ''
    # Desktop greeting with fortune
    function fish_greeting
      fortune -a | cowsay -n | lolcat
    end
    
    # Desktop-specific abbreviations
    set -U fish_user_abbreviations \
      'nr=sudo nixos-rebuild switch' \
      'nru=sudo nixos-rebuild switch --upgrade' \
      'col=colmena apply' \
      'run=nix run nixpkgs#' \
      'shell=nix shell nixpkgs#'
  '';
}
```

### 3.4 Update Server Hosts to Use Common Modules

```nix
# hosts/bee/default.nix
{ config, pkgs, lib, ... }: {
  imports = [
    ../common/base.nix
    ../common/shell.nix
    ../common/programs.nix
    ../common/ssh.nix
    ../common/tailscale.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];
  
  networking.hostName = "bee";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  system.stateVersion = "24.11";
}
```

## Phase 4: Desktop Configuration Consolidation

**Status**: ✅ Complete

### Task List - Phase 4
- [x] **4.1**: Migrate desktop config from `/nixos` to modular structure ✅
- [x] **4.2**: Create desktop-specific modules (graphics, hyprland, applications, gaming, etc.) ✅
- [x] **4.3**: Remove old `/nixos` directory after successful migration ✅
- [x] **4.4**: Clean up home-manager configuration duplications ✅
- [x] **4.5**: Implement proper separation between system and user configs ✅
- [x] **4.6**: Update hostname from JeremyDesktop to navi throughout configuration ✅
- [x] **4.7**: Fix platform-specific configurations (microcode, ARM support) ✅
- [x] **4.8**: Consolidate shell and environment configurations ✅

### 4.1 Desktop Module Structure Created

The desktop configuration was successfully migrated to a modular structure:

```
nix/modules/desktop/
├── default.nix              # Imports all desktop modules
├── graphics.nix             # AMD GPU configuration
├── hyprland.nix             # Hyprland window manager + tools
├── waybar.nix               # Status bar configuration
├── wayland.nix              # Wayland environment variables
├── applications.nix         # Desktop applications (browsers, communication)
├── development.nix          # Development tools and IDEs
├── gaming.nix               # Gaming and streaming tools
├── terminal.nix             # Terminal emulator
├── fonts.nix                # Desktop fonts
├── programs.nix             # Desktop programs (Steam, ADB, etc.)
├── services.nix             # Desktop services (printing, docker, etc.)
└── users.nix                # Desktop user configuration
```

### 4.2 Home-Manager Cleanup Completed

Home-manager was cleaned up to remove duplications with core modules:

```nix
# home-manager/packages.nix - Significantly reduced
# Removed packages now handled by desktop modules
# Kept only user-specific packages like killall, xsel, nvd, hcloud

# home-manager/shell.nix - Cleaned up
# Removed duplicated shell configurations
# Kept only user-specific abbreviations and Alacritty config
```

## Phase 5: DNS and Ingress Infrastructure

**Status**: ✅ Complete

### Task List - Phase 5
- [x] **5.1**: Create CoreDNS module (`common/dns.nix`) ✅
- [x] **5.2**: Create AdGuard Home module (`common/adguard.nix`) ✅
- [x] **5.3**: Create Traefik module (`common/traefik.nix`) ✅
- [x] **5.4**: Update bee config to include DNS/ingress services ✅
- [x] **5.5**: Generate self-signed certificates for .home domain ✅
- [x] **5.6**: Configure Tailscale IP assignment for bee ✅
- [x] **5.7**: Test all services build successfully ✅

### 5.1 DNS Architecture Update

**New Architecture** (as implemented):
- **AdGuard Home**: Primary DNS on port 53 - handles filtering and shows client IPs
- **CoreDNS**: Backup DNS on port 5354 - handles special cases if needed

```nix
# modules/services/dns/adguard.nix - Primary DNS
{
  services.adguardhome = {
    enable = true;
    mutableSettings = false;  # Fully declarative configuration
    settings = {
      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 53;  # Primary DNS port
        
        # Wildcard DNS rewrites (declarative)
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
      
      filtering = {
        # Filtering settings with rewrites
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
    };
  };
}

# modules/services/dns/coredns.nix - Backup DNS
{
  services.coredns = {
    enable = true;
    config = ''
      # Secondary DNS on port 5354
      home:5354 {
        # Handles .home domains if AdGuard fails
        hosts {
          100.74.102.74 bee.home adguard.home traefik.home dns.home
          fallthrough
        }
      }
      
      home.jeremyk.net:5354 {
        # Wildcard support using template
        template IN A home.jeremyk.net {
          match ^([a-zA-Z0-9-]+\.)?home\.jeremyk\.net\.$
          answer "{{ .Name }} 300 IN A 100.74.102.74"
          fallthrough
        }
      }
      
      .:5354 {
        # Forward other queries to AdGuard
        forward . 127.0.0.1:53
      }
    '';
  };
  
  networking.firewall = {
    allowedTCPPorts = [ 5354 ];
    allowedUDPPorts = [ 5354 ];
  };
}
```

### 5.2 Updated DNS Services Status

**DNS Architecture Changes**:
- Swapped ports: AdGuard (53), CoreDNS (5354)
- Fixed client IP visibility issue
- Implemented declarative wildcard DNS configuration
- Both `*.home` and `*.home.jeremyk.net` resolve to bee's Tailscale IP

**Key Configuration Note**:
DNS rewrites must be placed under `settings.filtering.rewrites` (not `settings.dns.rewrites`) for AdGuard Home to properly process them with `mutableSettings = false`.

### 5.3 Traefik Module

```nix
# hosts/common/traefik.nix
{ config, lib, pkgs, ... }: {
  services.traefik = {
    enable = true;
    
    staticConfigOptions = {
      global = {
        checkNewVersion = false;
        sendAnonymousUsage = false;
      };
      
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entrypoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        
        websecure = {
          address = ":443";
          http.tls = true;
        };
        
        internal = {
          address = "100.64.0.1:8443";  # Tailscale interface only
          http.tls = true;
        };
      };
      
      api = {
        dashboard = true;
      };
      
      log = {
        level = "INFO";
      };
    };
    
    dynamicConfigOptions = {
      http = {
        routers = {
          # Traefik dashboard
          traefik = {
            rule = "Host(`traefik.home`)";
            service = "api@internal";
            entryPoints = ["internal"];
            tls = true;
          };
          
          # AdGuard admin interface
          adguard = {
            rule = "Host(`adguard.home`)";
            service = "adguard";
            entryPoints = ["internal"];
            tls = true;
          };
          
          # Uptime Kuma (on halo)
          uptime = {
            rule = "Host(`uptime.home`)";
            service = "uptime";
            entryPoints = ["internal"];
            tls = true;
          };
        };
        
        services = {
          adguard = {
            loadBalancer = {
              servers = [{ url = "http://127.0.0.1:3000"; }];
            };
          };
          
          uptime = {
            loadBalancer = {
              servers = [{ url = "http://100.64.0.2:3001"; }];  # halo's Tailscale IP
            };
          };
        };
      };
      
      tls = {
        certificates = [
          {
            certFile = "/etc/traefik/certs/home.crt";
            keyFile = "/etc/traefik/certs/home.key";
            stores = ["default"];
          }
        ];
      };
    };
  };
  
  # Generate self-signed certificate for .home domain
  security.acme.certs."home" = {
    domain = "*.home";
    extraDomainNames = ["home"];
    # Use self-signed for internal domains
  };
  
  networking.firewall = {
    allowedTCPPorts = [ 80 443 ];
  };
}
```

### 5.4 Deploy Infrastructure Services to Bee

```nix
# hosts/bee/default.nix - Updated
{ config, pkgs, lib, ... }: {
  imports = [
    ../common/base.nix
    ../common/shell.nix
    ../common/programs.nix
    ../common/ssh.nix
    ../common/tailscale.nix
    ../common/dns.nix
    ../common/adguard.nix
    ../common/traefik.nix
    ./disko.nix
    ./hardware-configuration.nix
  ];
  
  networking.hostName = "bee";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Ensure Tailscale IP is stable
  networking.interfaces.tailscale0 = {
    ipv4.addresses = [{
      address = "100.64.0.1";
      prefixLength = 32;
    }];
  };
  
  system.stateVersion = "24.11";
}
```

## Phase 6: Deployment and Validation

**Status**: 🔄 In Progress (6/8 tasks complete)

### Task List - Phase 6
- [x] **6.1**: Generate hardware config for bee ✅
- [x] **6.2**: Deploy bee with nixos-anywhere ✅
- [x] **6.3**: Deploy halo (migrate from existing system) ✅
- [x] **6.4**: Test colmena deployment to all hosts ✅
- [x] **6.5**: Verify DNS services working on bee ✅
- [x] **6.6**: Test Traefik routing and .home domains ✅
- [ ] **6.7**: Verify Uptime Kuma accessible via Tailscale
- [ ] **6.8**: Run full system validation

### 6.1 Initial Deployment Commands

```bash
# Generate hardware config for bee (after booting from USB)
nixos-generate-config --show-hardware-config > hosts/bee/hardware-configuration.nix

# Deploy bee with nixos-anywhere
nix run github:nix-community/nixos-anywhere -- \
  --flake .#bee \
  root@<bee-ip>

# Deploy to halo (existing system)
colmena apply --on halo

# Deploy all systems
colmena apply

# Deploy specific changes
colmena apply --on bee,halo
```

### 6.2 Validation Steps

```bash
# Check all hosts are reachable
colmena exec -- uname -a

# Verify services on bee
colmena exec --on bee -- systemctl status coredns
colmena exec --on bee -- systemctl status adguardhome
colmena exec --on bee -- systemctl status traefik

# Test DNS resolution
dig @bee.home traefik.home
dig @100.64.0.1 adguard.home

# Test Traefik routing
curl -k https://traefik.home:8443
curl -k https://uptime.home:8443
```

### 6.3 DNS Services Status

**Deployed and Working:**
- **AdGuard Home**: Running on port 53 (primary DNS), web UI at http://100.74.102.74:3000
- **CoreDNS**: Running on port 5354 (backup DNS), handling special cases
- **Traefik**: Running with dashboard at http://100.74.102.74:9090
- **Wildcard domains**: Both `*.home` and `*.home.jeremyk.net` resolving to 100.74.102.74
- **Client IP visibility**: Fixed - AdGuard now shows real client IPs
- **Desktop DNS**: Using bee (100.74.102.74) as primary DNS server

**Access URLs**:
- AdGuard: http://adguard.home or https://adguard.home.jeremyk.net
- Traefik: http://traefik.home or https://traefik.home.jeremyk.net

### 6.4 Troubleshooting Commands

```bash
# Check build errors
nix flake check

# Compare configurations
nix-diff $(nix-build '<nixpkgs/nixos>' -A system --arg configuration ./hosts/jeremydesktop/default.nix) $(nix-build '<nixpkgs/nixos>' -A system --arg configuration ./nixos/configuration.nix)

# View effective configuration
nix eval --json .#nixosConfigurations.bee.config.services.traefik

# Check logs
colmena exec --on bee -- journalctl -u traefik -f
colmena exec --on bee -- journalctl -u coredns -f
```

## Next Steps

1. **Complete Phase 1**: Set up structure and validate desktop unchanged
2. **Deploy Bee**: Use nixos-anywhere for initial deployment
3. **Migrate Halo**: Update existing system to new configuration
4. **Test Services**: Verify DNS, AdGuard, and Traefik working
5. **Add Services**: Gradually add Nextcloud, *arr services, etc.
6. **Configure Backups**: Set up automated backups for stateful data

## Implementation Notes for New Agent Sessions

### Before Starting
1. **Read existing configs** to understand current state:
   - `nix/flake.nix` - current single-host setup
   - `nix/nixos/configuration.nix` - desktop config to preserve
   - `hetz-nix/configuration.nix` - reference for halo
   - `nix/home-manager/` - configs to migrate to system level

2. **Capture baseline** before any changes:
   ```bash
   cd /home/jeremy/dotfiles/nix
   ./baselines/capture-baseline.sh initial
   ```
   This captures only what matters:
   - System derivation path (the single source of truth)
   - Package closure for diff analysis
   - Critical values (hostname, stateVersion)

3. **Remember the SSH key**: `ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7YCbzW2kMJxx2YIN2XLGpLZMNzcTjB6WWmvKPVjVnR`

### Phase Execution Order
- **Phase 1**: Structure only, desktop unchanged
- **Phase 2**: Add server configs, test builds
- **Phase 3**: Create common modules (not used yet)  
- **Phase 4**: Gradually migrate desktop to common modules
- **Phase 5**: Move home-manager programs to system
- **Phase 6**: Deploy DNS/ingress infrastructure

### Key Validation Commands
```bash
# Always run after each phase
nix flake check
sudo nixos-rebuild dry-build --flake .#navi
colmena build

# Compare configs (should be identical until Phase 4)
diff /tmp/desktop-baseline.json /tmp/desktop-current.json
```

### Configuration Decisions Made
- All builds happen on `jeremydesktop` (no `buildOnTarget`)
- Tailscale routing enabled on all hosts (`useRoutingFeatures = "both"`)
- Uptime Kuma accessible only via Tailscale (bound to 127.0.0.1)
- Hetzner firewall handles main security for `halo`
- Services default to internal-only access (.home domains)
- Public access requires explicit Traefik configuration
- Shell/programs moved from home-manager to system level for sharing
- **Unraid hosts key services** (Radarr, Sonarr, Plex, Nextcloud) - NixOS handles ingress/DNS only

### Deployment Strategy
- Use `nixos-anywhere` for initial bee deployment
- Use `colmena apply` for ongoing deployments
- SSH over WAN initially (Tailscale access later)
- All hosts get same base configuration via common modules

## Phase 7: Ingress for Unraid Services (Bridge Mode)

**Status**: ⏸️ Not Started

**Purpose**: Cleanly expose Unraid bridge-mode containers via .home domains and Tailscale routing.

### Task List - Phase 7
- [ ] **7.1**: Map Unraid service IPs/ports in CoreDNS
- [ ] **7.2**: Configure Traefik dynamic routing to Unraid services
- [ ] **7.3**: Set up .home domains for Unraid services
- [ ] **7.4**: Configure Tailscale routing for Unraid access
- [ ] **7.5**: Test service routing (nextcloud.home, radarr.home, etc.)
- [ ] **7.6**: Verify services accessible via Tailscale but not directly on LAN

### 7.1 Update CoreDNS for Unraid Services

```nix
# hosts/common/dns.nix - Add Unraid services
home:53 {
  log
  errors
  hosts {
    # NixOS hosts
    100.64.0.1 bee.home
    100.64.0.2 halo.home
    100.64.0.3 pi.home
    
    # NixOS services
    100.64.0.1 traefik.home
    100.64.0.1 adguard.home
    100.64.0.1 dns.home
    100.64.0.2 uptime.home
    
    # Unraid services (routed via Traefik)
    100.64.0.1 nextcloud.home     # Route through bee Traefik
    100.64.0.1 radarr.home        # Route through bee Traefik
    100.64.0.1 sonarr.home        # Route through bee Traefik
    100.64.0.1 plex.home          # Route through bee Traefik
    100.64.0.1 prowlarr.home      # Route through bee Traefik
  }
}
```

### 7.2 Update Traefik for Unraid Service Routing

```nix
# hosts/common/traefik.nix - Add Unraid service routes
dynamicConfigOptions = {
  http = {
    routers = {
      # Existing NixOS services...
      
      # Unraid services
      nextcloud = {
        rule = "Host(`nextcloud.home`)";
        service = "nextcloud";
        entryPoints = ["internal"];
        tls = true;
      };
      
      radarr = {
        rule = "Host(`radarr.home`)";
        service = "radarr";
        entryPoints = ["internal"];
        tls = true;
      };
      
      sonarr = {
        rule = "Host(`sonarr.home`)";
        service = "sonarr";
        entryPoints = ["internal"];
        tls = true;
      };
      
      plex = {
        rule = "Host(`plex.home`)";
        service = "plex";
        entryPoints = ["internal"];
        tls = true;
      };
    };
    
    services = {
      # Existing services...
      
      # Unraid services (update IPs/ports based on actual setup)
      nextcloud = {
        loadBalancer = {
          servers = [{ url = "http://100.64.0.10:8443"; }];  # Unraid Tailscale IP
        };
      };
      
      radarr = {
        loadBalancer = {
          servers = [{ url = "http://100.64.0.10:7878"; }];
        };
      };
      
      sonarr = {
        loadBalancer = {
          servers = [{ url = "http://100.64.0.10:8989"; }];
        };
      };
      
      plex = {
        loadBalancer = {
          servers = [{ url = "http://100.64.0.10:32400"; }];
        };
      };
    };
  };
};
```

## Phase 8: Secure Routing Boundaries

**Status**: ⏸️ Not Started

**Purpose**: Harden access to prevent untrusted LAN devices from reaching admin interfaces directly.

### Task List - Phase 8
- [ ] **8.1**: Configure Tailscale ACLs to restrict Unraid access
- [ ] **8.2**: Bind admin interfaces to Tailscale IPs only
- [ ] **8.3**: Harden LAN firewall rules on bee
- [ ] **8.4**: Test that admin panels only accessible via Tailscale
- [ ] **8.5**: Document security boundaries and access methods

### 8.1 Tailscale ACL Configuration

```json
// tailscale ACL example (configure in Tailscale admin console)
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:admin"],
      "dst": ["100.64.0.10:*"]  // Unraid Tailscale IP
    },
    {
      "action": "accept", 
      "src": ["autogroup:members"],
      "dst": ["100.64.0.1:8443", "100.64.0.2:3001"]  // bee and halo services
    }
  ],
  "tagOwners": {
    "tag:admin": ["your-email@domain.com"]
  }
}
```

### 8.2 Secure Admin Interface Binding

```nix
# Update services to bind only to Tailscale interfaces
services.adguardhome.settings.web.bind_host = "100.64.0.1";  # bee Tailscale IP
services.uptime-kuma.settings.HOST = "100.64.0.2";          # halo Tailscale IP
```

## Phase 9: Observability and Health

**Status**: ⏸️ Not Started

**Purpose**: Add monitoring and health checking for the homelab infrastructure.

### Task List - Phase 9
- [ ] **9.1**: Add netdata to bee for system monitoring
- [ ] **9.2**: Configure health checks for core services
- [ ] **9.3**: Expose monitoring dashboards via Traefik
- [ ] **9.4**: Set up alerting for critical service failures

### 9.1 Add Netdata Monitoring

```nix
# hosts/common/monitoring.nix
{ config, lib, pkgs, ... }: {
  services.netdata = {
    enable = true;
    config = {
      global = {
        "default port" = "19999";
        "bind to" = "127.0.0.1";  # Local only - access via Traefik
      };
    };
  };
}
```

### 9.2 Add to Traefik Routing

```nix
# Add to traefik.nix
netdata = {
  rule = "Host(`metrics.home`)";
  service = "netdata";
  entryPoints = ["internal"];
  tls = true;
};

services.netdata = {
  loadBalancer = {
    servers = [{ url = "http://127.0.0.1:19999"; }];
  };
};
```

## Phase 10: DNS/Ingress Debug & Testing Utilities

**Status**: ⏸️ Not Started

**Purpose**: Add debugging tools and validation scripts for DNS and ingress testing.

### Task List - Phase 10
- [ ] **10.1**: Add debugging packages to bee
- [ ] **10.2**: Create DNS validation script
- [ ] **10.3**: Create ingress testing script

### 10.1 Add Debug Packages

```nix
# hosts/bee/default.nix - Add debugging tools
environment.systemPackages = with pkgs; [
  # Existing packages...
  
  # Network debugging
  dig
  nmap
  tcpdump
  wireshark-cli
  mtr
  
  # Service testing
  curl
  wget
  jq
  
  # Tailscale management
  tailscale
];
```

### 10.2 DNS Validation Script

```bash
# Create validation script
#!/usr/bin/env bash
# /etc/homelab-test/dns-test.sh

echo "🧪 Testing DNS Resolution"

# Test .home domain resolution
echo "Testing .home domains..."
for service in traefik adguard nextcloud radarr sonarr; do
  echo -n "  $service.home: "
  if dig @100.64.0.1 "$service.home" +short; then
    echo "✅"
  else
    echo "❌"
  fi
done

# Test service reachability
echo "Testing service connectivity..."
curl -k https://traefik.home:8443 >/dev/null 2>&1 && echo "  Traefik: ✅" || echo "  Traefik: ❌"
curl -k https://nextcloud.home:8443 >/dev/null 2>&1 && echo "  Nextcloud: ✅" || echo "  Nextcloud: ❌"
```

## Future Enhancements (Optional)

### Phase 11: GitOps Pipeline (Future)
- Automated deployment on git push
- CI/CD with Woodpecker CI or GitHub Actions
- Automated testing and rollback capabilities

### Phase 12: Advanced Secrets Management
- Document agenix workflows
- Create secrets validation scripts
- Implement secret rotation procedures

### Architecture Notes

This expanded plan maintains the principle of **NixOS for infrastructure, Unraid for applications**:

- **NixOS (bee, halo, pi)**: DNS, ingress, monitoring, system management
- **Unraid**: Application hosting (Nextcloud, *arr stack, Plex, etc.)
- **Tailscale**: Secure networking and access control
- **Traefik**: Unified ingress controller routing to both NixOS and Unraid services

The architecture avoids complex Docker migrations while providing centralized, declarative management of the networking and access layer.