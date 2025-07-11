# NixOS systemd service configuration for grist-payment-updater
{ config, lib, pkgs, secrets, ... }:

let
  python = pkgs.python3.withPackages (ps: with ps; [
    httpx
    python-dateutil
    python-dotenv
  ]);
in
{
  # Deploy the grist-payment-updater script
  environment.etc."grist-payment-updater/main.py".source = ./main.py;
  environment.etc."grist-payment-updater/main.py".mode = "0755";

  # System service definition
  systemd.services.grist-payment-updater = {
    description = "Grist Payment Date Updater";
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "grist-updater";
      Group = "grist-updater";
      ExecStart = "${python}/bin/python3 /etc/grist-payment-updater/main.py";
      EnvironmentFile = "/etc/grist-payment-updater/env";
    };
  };
  
  # Timer to run daily at 8 AM
  systemd.timers.grist-payment-updater = {
    description = "Run Grist Payment Date Updater daily at 8 AM";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "*-*-* 08:00:00";
      Persistent = true;
    };
  };
  
  # Create user for the service
  users.users.grist-updater = {
    isSystemUser = true;
    group = "grist-updater";
    description = "Grist Payment Updater service user";
  };
  
  users.groups.grist-updater = {};
  
  # Create environment file with secrets
  environment.etc."grist-payment-updater/env" = {
    text = ''
      GRIST_API_KEY=${secrets.grist.api_key}
      GRIST_PROXY_AUTH=${secrets.grist.proxy_auth}
      DRY_RUN=false
    '';
    mode = "0600";
    user = "grist-updater";
    group = "grist-updater";
  };

  # Create directory for environment file
  systemd.tmpfiles.rules = [
    "d /etc/grist-payment-updater 0750 root grist-updater -"
  ];
}