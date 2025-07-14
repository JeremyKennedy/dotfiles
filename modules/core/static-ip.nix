# Static IP configuration module
{
  config,
  lib,
  ...
}: let
  cfg = config.networking.staticIP;
  inherit (import ./hosts.nix) hosts;
in {
  options.networking.staticIP = {
    enable = lib.mkEnableOption "static IP configuration";
    address = lib.mkOption {
      type = lib.types.str;
      description = "Static IP address with CIDR (e.g., 192.168.1.250/24)";
    };
    gateway = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.1";
      description = "Gateway IP address";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.network.networks."10-ethernet" = {
      matchConfig.Name = "en*";
      networkConfig = {
        Address = cfg.address;
        Gateway = cfg.gateway;
        DNS = [hosts.bee.tailscaleIp]; # bee DNS server (Tailscale IP)
        Domains = ["~home" "~home.jeremyk.net"]; # Search domains
      };
    };
  };
}
