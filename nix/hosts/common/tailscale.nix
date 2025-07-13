{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";  # Enable routing on all hosts
  };
  
  networking.firewall.trustedInterfaces = ["tailscale0"];
}