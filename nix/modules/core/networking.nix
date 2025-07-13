# Basic networking configuration for all hosts
{
  config,
  lib,
  pkgs,
  ...
}: {
  # Enable NetworkManager for easier network management
  networking.networkmanager.enable = lib.mkDefault true;

  # Basic network optimizations
  boot.kernel.sysctl = {
    # Increase Linux autotuning TCP buffer limits
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";

    # Increase the maximum number of incoming connections
    "net.core.somaxconn" = 4096;

    # Enable TCP Fast Open
    "net.ipv4.tcp_fastopen" = 3;
  };
}
