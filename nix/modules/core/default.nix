# Core modules imported by ALL hosts - truly universal
{...}: {
  imports = [
    ./base.nix # Essential Nix settings and packages
    ./boot.nix # Boot configuration
    ./networking.nix # Basic network configuration
    ./static-ip.nix # Static IP configuration option
    ./security.nix # Firewall and fail2ban
    ./ssh.nix # SSH server
    ./tailscale.nix # VPN configuration
    ./performance.nix # Performance tuning and optimizations
    ./hardware.nix # Hardware-specific optimizations
    ./shell.nix # Fish shell, starship prompt for all users
    ./git.nix # Git configuration for all users
  ];
}
