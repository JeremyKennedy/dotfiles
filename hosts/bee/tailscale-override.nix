# Bee-specific Tailscale configuration override
#
# Bee serves as the network gateway for homelab:
# - Advertises 192.168.1.0/24 routes to make local network accessible via Tailscale
# - Does NOT accept routes (servers don't need remote network access)
# - Client devices (like phone) can accept these routes to reach local network via Tailscale
# - This allows phone to reach local devices even when using Tailscale exit nodes
{
  services.tailscale.extraUpFlags = [
    "--accept-dns"  # Allow Tailscale DNS for *.sole-bigeye.ts.net resolution
    "--advertise-routes=192.168.1.0/24"  # Share local network with Tailscale
    "--ssh"  # Enable Tailscale SSH
  ];
}