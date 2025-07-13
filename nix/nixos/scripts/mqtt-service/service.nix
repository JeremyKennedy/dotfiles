# NixOS systemd service configuration for mqtt-service
{
  config,
  lib,
  pkgs,
  ...
}: let
  python = pkgs.python3.withPackages (ps: with ps; [paho-mqtt]);
in {
  # Deploy the mqtt service script
  environment.etc."mqtt-service/main.py".source = ./main.py;
  environment.etc."mqtt-service/main.py".mode = "0755";

  # Define systemd service to run under the jeremy user and connect to PipeWire/Hyprland
  systemd.services.mqtt-service = {
    enable = true;
    description = "MQTT service for volume and game mode control";
    after = ["network.target" "graphical-session.target"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      User = "jeremy";
      Environment = [
        "XDG_RUNTIME_DIR=/run/user/1000"
        "WAYLAND_DISPLAY=wayland-1"
        "XDG_SESSION_TYPE=wayland"
        "QT_QPA_PLATFORM=wayland"
        "GDK_BACKEND=wayland"
        "PATH=/run/current-system/sw/bin:/home/jeremy/.nix-profile/bin"
      ];
      ExecStart = "${python}/bin/python3 /etc/mqtt-service/main.py";
      Restart = "always";
      RestartSec = "5";
    };
  };
}
