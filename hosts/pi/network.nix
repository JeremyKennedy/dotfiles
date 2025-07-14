# Host-specific networking configuration for pi
{
  config,
  pkgs,
  ...
}: {
  networking.hostName = "pi";

  # Static IP configuration
  networking.staticIP = {
    enable = true;
    address = "192.168.1.230/24";
  };
}
