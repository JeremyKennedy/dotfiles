{config, ...}: {
  age.secrets = {
    cloudflare_dns_token = {
      file = ../../secrets/cloudflare_dns_token.age;
      owner = "traefik";
      group = "traefik";
    };
  };
}
