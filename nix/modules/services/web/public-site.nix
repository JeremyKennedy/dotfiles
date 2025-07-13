# Barebone public site - returns 200 OK
{
  config,
  pkgs,
  lib,
  ...
}: {
  # Simple HTTP server that returns 200 OK
  systemd.services.public-site = {
    description = "Simple public site";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8888 --bind 127.0.0.1";
      WorkingDirectory = "/var/lib/public-site";
      User = "public-site";
      Group = "public-site";
      Restart = "always";

      # Security hardening
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      NoNewPrivileges = true;
      ReadWritePaths = "/var/lib/public-site";
    };
  };

  # Create user for the service
  users.users.public-site = {
    isSystemUser = true;
    group = "public-site";
    home = "/var/lib/public-site";
    createHome = true;
  };

  users.groups.public-site = {};

  # Create a simple index.html that returns 200 OK
  systemd.tmpfiles.rules = [
    "d /var/lib/public-site 0755 public-site public-site -"
    "f /var/lib/public-site/index.html 0644 public-site public-site - OK"
  ];
}
