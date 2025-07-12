# NixOS Multi-Host Homelab Deployment Plan

## Overview

This plan outlines the phased approach to refactor the existing single-host NixOS configuration into a multi-host setup supporting `jeremydesktop`, `bee`, `halo`, and `pi` hosts. The approach prioritizes maintaining desktop functionality while enabling declarative infrastructure management via Colmena.

## Key Requirements

- **Secrets**: Already handled via agenix (no setup needed)
- **Build Strategy**: All builds happen on `jeremydesktop` (no `buildOnTarget`)
- **Networking**: Tailscale routing enabled on all hosts
- **Firewall**: Hetzner firewall handles `halo`, minimal NixOS firewall
- **Deployment**: SSH over WAN initially, Tailscale later
- **Security**: Uptime Kuma not publicly exposed
- **Dev Environment**: Using `devenv.nix`

## Phase 1: Refactor for Multi-Host (Desktop Unchanged)

### 1.1 Create Directory Structure

```
nix/
├── hosts/
│   ├── common/
│   │   ├── base.nix         # Core nix settings, basic packages
│   │   ├── shell.nix        # Fish, starship, shell utilities
│   │   ├── programs.nix     # Git, ripgrep, tmux, etc.
│   │   ├── ssh.nix          # SSH configuration
│   │   ├── tailscale.nix    # Tailscale with routing
│   │   ├── dns.nix          # CoreDNS configuration
│   │   ├── traefik.nix      # Traefik ingress controller
│   │   └── adguard.nix      # AdGuard Home DNS filtering
│   ├── jeremydesktop/
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
├── devenv.nix               # Development environment
└── .envrc                   # direnv integration
```

### 1.2 Update flake.nix

```nix
{
  description = "Multi-host NixOS configuration";
  
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    
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

### 1.5 Validation

```bash
# Ensure desktop configuration unchanged
sudo nixos-rebuild dry-build --flake .#jeremydesktop > /tmp/before.txt
# After changes
sudo nixos-rebuild dry-build --flake .#jeremydesktop > /tmp/after.txt
diff /tmp/before.txt /tmp/after.txt

# Test flake
nix flake check
```

## Phase 2: Add Server Hosts Configuration

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

## Phase 3: Extract and Share Common Configuration

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

## Phase 4: Move Home-Manager Programs to System Level

### 4.1 Update Home-Manager Configuration

Reduce home-manager to only GUI-specific applications:

```nix
# home-manager/programs.nix
{
  config,
  pkgs,
  ...
}: {
  programs = {
    # Remove: git, ripgrep, btop, tmux, nnn, direnv, gh, broot
    # These are now in hosts/common/programs.nix
    
    # Keep GUI-specific programs here
    firefox.enable = true;
    vscode.enable = true;
    # etc.
  };
}
```

### 4.2 Update Shell Configuration in Home-Manager

```nix
# home-manager/shell.nix
{
  config,
  pkgs,
  ...
}: {
  programs = {
    # Remove fish config - now in system
    # Keep only GUI terminal config
    alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
      };
    };
  };
}
```

## Phase 5: DNS and Ingress Infrastructure

### 5.1 CoreDNS Module

```nix
# hosts/common/dns.nix
{ config, lib, pkgs, ... }: {
  services.coredns = {
    enable = true;
    config = ''
      .:53 {
        forward . 127.0.0.1:5353  # Forward to AdGuard
        cache 30
        log
        errors
      }
      
      home:53 {
        log
        errors
        hosts {
          # Host entries
          100.64.0.1 bee.home
          100.64.0.2 halo.home
          100.64.0.3 pi.home
          
          # Service entries
          100.64.0.1 traefik.home
          100.64.0.1 adguard.home
          100.64.0.1 dns.home
          100.64.0.2 uptime.home
          
          # Future services
          100.64.0.1 nextcloud.home
          100.64.0.1 radarr.home
          100.64.0.1 sonarr.home
        }
      }
    '';
  };
  
  networking.firewall = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
```

### 5.2 AdGuard Home Module

```nix
# hosts/common/adguard.nix
{ config, lib, pkgs, ... }: {
  services.adguardhome = {
    enable = true;
    mutableSettings = false;
    settings = {
      bind_host = "0.0.0.0";
      bind_port = 5353;
      
      web = {
        bind_host = "127.0.0.1";  # Local only
        bind_port = 3000;
      };
      
      dns = {
        bind_hosts = ["0.0.0.0"];
        port = 5353;
        
        upstream_dns = [
          "https://dns.cloudflare.com/dns-query"
          "https://dns.google/dns-query"
          "1.1.1.1"
          "8.8.8.8"
        ];
        
        filtering_enabled = true;
        filters_update_interval = 24;
        
        blocked_response_ttl = 10;
        
        cache_size = 4194304;  # 4MB
        cache_ttl_min = 0;
        cache_ttl_max = 86400;
      };
      
      filters = [
        {
          enabled = true;
          url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
          name = "AdGuard DNS filter";
        }
        {
          enabled = true;
          url = "https://someonewhocares.org/hosts/zero/hosts";
          name = "Dan Pollock's List";
        }
      ];
    };
  };
}
```

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

### 6.3 Troubleshooting Commands

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

## Notes

- All builds happen on `jeremydesktop` (no `buildOnTarget`)
- Tailscale routing enabled on all hosts
- Uptime Kuma accessible only via Tailscale
- Hetzner firewall handles main security for `halo`
- Services default to internal-only access
- Public access requires explicit Traefik configuration