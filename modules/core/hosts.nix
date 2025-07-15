# Centralized host configuration
#
# This module defines all hosts in the homelab with their various network addresses.
# Import this module to access host information instead of hardcoding IPs/domains.
#
# Usage:
#   let
#     inherit (import ./modules/core/hosts.nix) hosts;
#   in {
#     # Access host info: hosts.bee.ip, hosts.tower.tailscaleDomain, etc.
#   }
{
  hosts = {
    # DNS and network services mini PC
    bee = {
      ip = "192.168.1.245";
      tailscaleIp = "100.74.102.74";
      tailscaleDomain = "bee.sole-bigeye.ts.net";
      hostname = "bee";
    };

    # Desktop workstation
    navi = {
      ip = "192.168.1.250";
      tailscaleIp = "100.75.187.40";
      tailscaleDomain = "navi.sole-bigeye.ts.net";
      hostname = "navi";
    };

    # Unraid server
    tower = {
      ip = "192.168.1.240";
      tailscaleIp = "100.115.172.123";
      tailscaleDomain = "tower.sole-bigeye.ts.net";
      hostname = "tower";
    };

    # Hetzner VPS
    halo = {
      ip = "100.78.79.103";  # Use Tailscale IP as primary since it's remote
      publicIp = "46.62.144.212";
      tailscaleIp = "100.78.79.103";
      tailscaleDomain = "halo.sole-bigeye.ts.net";
      hostname = "halo";
    };

    # Raspberry Pi
    pi = {
      ip = "192.168.1.230";
      tailscaleIp = "100.124.210.114";
      tailscaleDomain = "pi.sole-bigeye.ts.net";
      hostname = "pi";
    };
  };

  # Tailscale network domain
  tailscaleDomain = "sole-bigeye.ts.net";
}
