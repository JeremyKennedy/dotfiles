# Host-specific networking configuration for halo
{
  config,
  pkgs,
  ...
}: {
  networking.hostName = "halo";

  # VPS uses Hetzner DHCP - no static IP config needed
  # All networking handled by cloud provider

  # Firewall configuration
  # SECURITY: Services bind to 0.0.0.0 but are protected by firewall rules.
  # Only Tailscale traffic can reach them via trustedInterfaces.
  # Hetzner firewall provides additional protection at network level.
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"]; # Only trust Tailscale traffic
    checkReversePath = "loose"; # Required for exit nodes
    # No ports opened - tailscale0 trusted interface allows access
  };
}
