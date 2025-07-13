# Common performance optimizations for all hosts
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Enable zram swap for better memory utilization
  # Beneficial for all hosts: servers get more effective RAM, desktop gets better responsiveness
  zramSwap = {
    enable = true;
    # Default settings work well for most use cases
    # Can be overridden per-host if needed
  };

  # Out of memory protection
  # Prevents system freezes when memory is exhausted
  services.earlyoom = {
    enable = lib.mkDefault true;
    # Conservative settings that work well for servers and desktop
    freeMemThreshold = lib.mkDefault 2; # Start killing when <2% free memory
    freeSwapThreshold = lib.mkDefault 2; # Start killing when <2% free swap
  };
}
