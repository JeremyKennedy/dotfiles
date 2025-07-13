# NixOS systemd service configuration for grist-payment-updater
{
  config,
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (ps:
    with ps; [
      httpx
      python-dateutil
      python-dotenv
    ]);
in {
  # Deploy the grist-payment-updater script
  environment.etc."grist-payment-updater/main.py".source = ./main.py;
  environment.etc."grist-payment-updater/main.py".mode = "0755";

  # System service definition
  systemd.services.grist-payment-updater = {
    description = "Grist Payment Date Updater";
    after = ["network.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "grist-updater";
      Group = "grist-updater";
      ExecStart = "${python}/bin/python3 /etc/grist-payment-updater/main.py";
      RuntimeDirectory = "grist-payment-updater";
      RuntimeDirectoryMode = "0700";
    };
    environment = {
      DRY_RUN = "false";
      GRIST_API_KEY_FILE = "${config.age.secrets.grist_api_key.path}";
      GRIST_PROXY_AUTH_FILE = "${config.age.secrets.grist_proxy_auth.path}";
    };
  };

  # Timer to run daily at 8 AM
  systemd.timers.grist-payment-updater = {
    description = "Run Grist Payment Date Updater daily at 8 AM";
    wantedBy = ["timers.target"];
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
}
