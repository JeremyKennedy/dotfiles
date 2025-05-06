{
  config,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (ps: with ps; [paho-mqtt]);
in {
  # Deploy the standalone MQTT volume subscriber script
  environment.etc."mqtt-volume/mqtt_volume.py".source = ./scripts/mqtt_volume.py;
  environment.etc."mqtt-volume/mqtt_volume.py".mode = "0755";

  # Define systemd service to run under the jeremy user and connect to PipeWire
  systemd.services.mqtt-volume = {
    enable = true;
    description = "MQTT volume subscriber";
    after = ["network.target"];
    serviceConfig = {
      User = "jeremy";
      Environment = "XDG_RUNTIME_DIR=/run/user/1000";
      ExecStart = "${python}/bin/python3 /etc/mqtt-volume/mqtt_volume.py";
      Restart = "always";
    };
  };
}
