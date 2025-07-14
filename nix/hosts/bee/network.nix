# Host-specific networking configuration for bee
{
  config,
  pkgs,
  ...
}: {
  networking.hostName = "bee";

  # Static IP configuration
  networking.staticIP = {
    enable = true;
    address = "192.168.1.245/24";
  };
}
