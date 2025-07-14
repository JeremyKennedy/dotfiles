{config, ...}: {
  age.secrets.tailscale_auth_key = {
    file = ../../secrets/tailscale_auth_key.age;
    mode = "400";
    owner = "root";
  };

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both"; # Enable routing on all hosts
    authKeyFile = config.age.secrets.tailscale_auth_key.path;
    extraUpFlags = [
      "--accept-dns"
      "--ssh"
    ];
  };

  networking.firewall.trustedInterfaces = ["tailscale0"];
}
