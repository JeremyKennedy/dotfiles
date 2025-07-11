{
  modulesPath,
  lib,
  pkgs,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh.enable = true;

  # SSH brute force protection
  services.fail2ban = {
    enable = true;
    maxretry = 3;
    ignoreIP = ["100.64.0.0/10"]; # Tailscale network
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL7YCbzW2kMJxx2YIN2XLGpLZMNzcTjB6WWmvKPVjVnR"
  ];

  # Basic system settings
  networking.hostName = "hetz-nix";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    jujutsu
    fish
    claude-code
    curl
  ];

  # Set fish as root's shell
  users.users.root.shell = pkgs.fish;
  programs.fish.enable = true;
  programs.starship.enable = true;

  # Uptime Kuma configuration - accessible via Tailscale
  services.uptime-kuma = {
    enable = true;
    settings = {
      HOST = "hetz-nix.sole-bigeye.ts.net";
      PORT = "3001";
    };
  };

  # Tailscale configuration
  services.tailscale.enable = true;
  services.tailscale.useRoutingFeatures = "both";

  # Enable IP forwarding for Tailscale exit node
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  # Firewall configuration
  networking.firewall = {
    enable = true;
    trustedInterfaces = ["tailscale0"];
    checkReversePath = "loose"; # Required for exit nodes
  };

  # Performance and maintenance
  boot.tmp.cleanOnBoot = true;
  zramSwap.enable = true;

  # Optimize network for Tailscale exit node performance
  systemd.services.tailscale-optimize-network = {
    description = "Optimize network settings for Tailscale";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -K enp1s0 rx-udp-gro-forwarding on";
      RemainAfterExit = true;
    };
  };

  # Automatic updates
  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
    dates = "02:00";
    randomizedDelaySec = "45min";
  };

  # Nix garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  nix.settings.auto-optimise-store = true;

  system.stateVersion = "24.05";
}
